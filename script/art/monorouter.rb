# This app is a raft. — 이 앱도 뗏목이다.
#
# 만드는 사람의 연장 — MonoRouter 로 그림 모델을 부른다(STATUS 「바깥 AI 는 그림을 만드는 연장일
# 뿐이다. 앱은 부르지 않는다.」). 앱은 이 파일을 모른다: app/ · config/ · lib/ 어디서도 require
# 하지 않는다(test/locks/form/art_tool_test.rb). Ruby 표준 라이브러리만 쓴다.
#
# 열쇠는 저장소 맨 위의 .env.art 에서만 읽는다. 값은 출력 · 로그 · 에러 메시지 · 파일 어디에도
# 남기지 않는다 — 에러를 찍을 때는 상태 번호와 응답 본문만, 요청 헤더는 찍지 않는다. 응답
# 본문에 열쇠가 되돌아와 섞여 있으면 그 자리를 가린다.
require "json"
require "net/http"
require "uri"
require "base64"
require "fileutils"

module MonoRouter
  ROOT = File.expand_path("../..", __dir__)
  ENV_FILE = File.join(ROOT, ".env.art")
  KEY_NAME = "MONOROUTER_MEDIA_KEY"
  BASE = "https://monogpt.kr/api/monorouter/v1"
  OUT = File.join(ROOT, "tmp/art")

  class Error < StandardError; end

  module_function

  def key
    @key ||= begin
      raise Error, ".env.art 가 없다 — 저장소 맨 위에 #{KEY_NAME}=… 한 줄" unless File.exist?(ENV_FILE)

      line = File.readlines(ENV_FILE, chomp: true).find { |l| l.start_with?("#{KEY_NAME}=") }
      value = line&.split("=", 2)&.last.to_s.strip
      raise Error, ".env.art 에 #{KEY_NAME} 이 비어 있다" if value.empty?

      value
    end
  end

  # 응답 본문에 열쇠가 섞여 돌아오는 일에 대비해 가린다.
  def hide(text)
    text.to_s.dup.force_encoding(Encoding::UTF_8).scrub.gsub(key, "[열쇠 가림]")
  end

  # 크레딧 — 호출은 계정 잔액에서 빠진다(선불 따로 없음: prepaid_remaining_credits 0). 이 키가 쓴 값은
  # used_credits 의 앞뒤 차이로 잰다. 멈춤 줄은 이 키의 예산(BUDGET): used_credits 가 거기 닿으면 멈춘다.
  # 응답의 key_preview 는 읽지도 찍지도 않는다.
  BUDGET = 30_000
  MOST_PER_RUN = 4

  def used
    value = get("/credits")["used_credits"]
    raise Error, "크레딧 응답에 used_credits 가 없다" unless value.is_a?(Numeric)

    value
  end

  def check_budget!(used_now = used)
    raise Error, "예산에 닿았다 — 이 키의 used_credits #{used_now} / #{BUDGET}. 멈춘다." if used_now >= BUDGET

    used_now
  end

  # 한 장을 부르고, 앞뒤 used_credits 로 쓴 값을 재어 장부에 적는다. 돌려주는 것은 경로와 쓴 값.
  def draw(name:, model:, prompt:, size: "1K", aspect: "1:1", references: [])
    before = check_budget!
    response = gemini_image(model:, prompt:, size:, aspect:, references:)
    paths = save_images(response, name)
    after = used
    ledger(name:, model:, size:, count: paths.size, spent: after - before, total: after)
    [ paths, after - before ]
  end

  def models
    get("/models")
  end

  # Gemini 의 네이티브 길 — generateContent. 참조 그림은 inline_data(base64)로 글 앞에 붙인다.
  def gemini_image(model:, prompt:, size: "1K", aspect: "1:1", references: [])
    parts = references.map do |path|
      { inline_data: { mime_type: mime(path), data: Base64.strict_encode64(File.binread(path)) } }
    end
    parts << { text: prompt }
    body = {
      contents: [ { role: "user", parts: parts } ],
      generationConfig: { responseModalities: [ "IMAGE" ], imageConfig: { imageSize: size, aspectRatio: aspect } }
    }
    post("/gemini/v1beta/models/#{model}:generateContent", body)
  end

  # 응답에서 그림을 꺼내 tmp/art/ 에 둔다. 돌려주는 것은 경로들.
  def save_images(response, name)
    FileUtils.mkdir_p(OUT)
    parts = Array(response.dig("candidates", 0, "content", "parts"))
    images = parts.filter_map { |part| part["inlineData"] || part["inline_data"] }
    raise Error, "응답에 그림이 없다: #{hide(response.to_json)[0, 400]}" if images.empty?

    images.each_with_index.map do |image, index|
      extension = (image["mimeType"] || image["mime_type"]).to_s.split("/").last || "png"
      path = File.join(OUT, "#{name}-#{index + 1}.#{extension}")
      File.binwrite(path, Base64.decode64(image["data"]))
      path
    end
  end

  # 장부 — 날짜, 그림 이름, 모델, 해상도, 장 수, 쓴 크레딧, 이 키의 used_credits 누계.
  def ledger(name:, model:, size:, count:, spent:, total:)
    FileUtils.mkdir_p(OUT)
    path = File.join(OUT, "ledger.csv")
    File.write(path, "date,name,model,size,count,spent,used_total\n") unless File.exist?(path)
    File.open(path, "a") { |f| f.puts([ Time.now.strftime("%F %T"), name, model, size, count, spent, total ].join(",")) }
  end

  def get(path) = request(Net::HTTP::Get.new(uri(path)))

  def post(path, body)
    req = Net::HTTP::Post.new(uri(path))
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body)
    request(req)
  end

  def uri(path) = URI("#{BASE}#{path}")

  def request(req)
    req["Authorization"] = "Bearer #{key}"
    res = Net::HTTP.start(req.uri.host, req.uri.port, use_ssl: true, open_timeout: 15, read_timeout: 300) { |http| http.request(req) }
    unless res.is_a?(Net::HTTPSuccess)
      # 요청 헤더는 찍지 않는다. 길 · 상태 · 본문(열쇠는 가린다)만.
      raise Error, "#{req.method} #{req.uri.path} → #{res.code} #{hide(res.body)[0, 600]}"
    end

    JSON.parse(res.body.dup.force_encoding(Encoding::UTF_8))
  end

  def mime(path)
    { ".png" => "image/png", ".jpg" => "image/jpeg", ".jpeg" => "image/jpeg", ".webp" => "image/webp" }.fetch(File.extname(path).downcase)
  end
end
