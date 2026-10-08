# This app is a raft. — 이 앱도 뗏목이다.
#
# 글꼴. 한글 명조는 가로획이 가늘어 작은 크기에서 먼저 사라진다.
# 명조는 짧고 큰 글(18px 이상)에만, 읽는 글은 모두 고딕이다.
require "test_helper"

class TypeTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  SERIF_FLOOR = 18

  TOKENS = {
    voice: "400 1.5rem/1.6 var(--serif)",
    title: "700 1.25rem/1.5 var(--serif)",
    body: "400 0.9375rem/1.7 var(--sans)",
    ui: "400 0.9375rem/1.4 var(--sans)",
    label: "400 0.75rem/1.5 var(--sans)"
  }.freeze

  # 읽는 글 — 카드의 한 줄, 방 머리의 한 줄, 선방의 한 줄, 안내의 본문과 인용,
  # 아홉 자리의 설명, 사경의 글자 풀이.
  READING = [ ".compound__card-line", ".hall-header__line", ".quote",
              ".guide > p:not(.lead):not(.aside), .guide blockquote p", ".copy-notes dd" ].freeze

  # 옅은 --mute 가 설 수 있는 자리 — 출전 · 한자 곁말 · 닫는 손잡이 · 음원의 출처 같은 보조.
  MUTE_PLACES = %w[.threshold__source .compound__card-source .guide\ .source .compound__card-han
                   .compound__card-close .bell-hall__source].freeze

  test "글꼴 다섯은 :root 의 토큰이다" do
    root = css[/:root \{.*?\n\}/m]

    TOKENS.each { |name, value| assert_match(/--type-#{name}: #{Regexp.escape(value)};/, root) }
    # 큰 글은 붓이다 — 알파벳 · 한자 · 한글 순으로 서고, 셋 다 없을 때만 기기 명조로 떨어진다.
    assert_match(/--serif: "Caveat Brush", "LXGW WenKai TC", "East Sea Dokdo", "Noto Serif KR",/, root)
    assert_match(/--sans: "Noto Sans KR",/, root)
    assert_match(/--ink-soft: #4a524f;/, root)
  end

  # 붓 셋은 저장소 안의 파일이다. 글꼴 서비스를 부르지 않는다(제6조) — 바깥을 부르지
  # 않는다는 약속은 spirit_promise_test 가 지키고, 여기서는 파일이 제자리에 있는지를 본다.
  # 알파벳 붓은 라틴 자리에만, 한자 붓은 한자 자리에만 선다 — 한글은 동해독도의 것이다.
  test "붓 셋은 저장소 안의 파일이고, 저마다 제 글자 자리에만 선다" do
    faces = css.scan(/@font-face \{([^}]*)\}/m).flatten
    assert_equal 3, faces.size, "글꼴이 셋이 아니다"

    # 알파벳 붓은 글자(A–Z · a–z)에만 — 마침표 하나로 한국어 화면에 실리지 않게.
    { "Caveat Brush" => /unicode-range: U\+0041-005A, U\+0061-007A;/, "LXGW WenKai TC" => /U\+4E00-9FFF/, "East Sea Dokdo" => nil }.each do |family, range|
      face = faces.find { |body| body.include?(%(font-family: "#{family}")) }
      assert face, "#{family} 의 @font-face 가 없다"
      file = face[/src: url\("([\w-]+\.woff2)"\) format\("woff2"\)/, 1]
      assert file, "#{family} 가 저장소 안의 woff2 가 아니다"
      assert Rails.root.join("app/assets/fonts", file).exist?, "#{file} 이 app/assets/fonts 에 없다"
      assert_no_match(/https?:/, face, "#{family} 가 바깥에서 온다")
      range ? assert_match(range, face) : assert_no_match(/unicode-range/, face, "한글 붓의 자리를 좁혔다")
    end
    assert_includes Rails.application.config.assets.paths.map(&:to_s), Rails.root.join("app/assets/fonts").to_s
  end

  # 문의 현판 위 한자는 읽는 글이 아니라 그림의 일부다 — 그림의 비율로
  # 줄어든다(먼 문일수록 작게). 획이 단순한 옛 이름 세 자뿐이다.
  # 조감도의 전각 이름 아래 작은 한자도 같다 — 그림 위의 곁말이지 읽는 글이 아니다.
  DRAWN = %w[.gate-plaque__board .compound__han].freeze

  test "명조는 18px 이상에만 쓴다" do
    serif_classes = []

    rules.each do |selector, body|
      next unless serif?(body)
      next if DRAWN.include?(selector)

      size = size_of(body)
      assert size, "명조의 크기가 정해지지 않았다(물려받으면 작아진다): #{selector}"
      assert_operator size, :>=, SERIF_FLOOR, "#{SERIF_FLOOR}px 보다 작은 명조: #{selector} (#{size}px)"
      serif_classes.concat(selector.scan(/\.[\w-]+/).last(1))
    end

    # 명조인 자리를 다른 규칙이 작게 덮어쓰는 것도 같다.
    rules.each do |selector, body|
      next if serif?(body) || !(size = size_of(body))
      next unless size < SERIF_FLOOR && body.match?(/font(?:-size)?:/)

      target = selector.gsub(/:not\([^)]*\)/, "")
      hit = serif_classes.uniq.find { |name| target.match?(/#{Regexp.escape(name)}(?![\w-])/) }
      assert_nil hit, "#{hit} 의 명조를 #{selector} 가 #{size}px 로 줄인다"
    end
  end

  test "읽는 글은 고딕 본문이고 색은 --ink-soft 다" do
    READING.each do |selector|
      body = rules.find { |one, _| one == selector }&.last
      assert body, "#{selector} 규칙이 없다"
      assert_match(/font: var\(--type-body\)/, body, "#{selector} 가 고딕 본문이 아니다")
      assert_match(/(?<![-\w])color: var\(--ink-soft\)/, body, "#{selector} 의 색이 --ink-soft 가 아니다")
    end
  end

  test "--mute 는 보조에만 쓴다" do
    rules.each do |selector, body|
      next unless body.match?(/(?<![-\w])color: var\(--mute\)/)

      assert_includes MUTE_PLACES, selector, "읽는 글이 --mute 로 흐리다: #{selector}"
    end
  end

  test "손잡이 — 버튼은 고딕이다" do
    %w[.button-primary button,\ input[type="submit"]].each do |selector|
      body = rules.find { |one, _| one == selector }&.last
      assert_match(/font: var\(--type-ui\)/, body, "#{selector} 가 고딕 손잡이가 아니다")
    end
  end

  private
    def css = CSS.read

    def rules
      @rules ||= css.gsub(%r{/\*.*?\*/}m, "").sub(/:root \{.*?\n\}/m, "")
                    .scan(/([^{}@]+)\{([^{}]*)\}/).map { |selector, body| [ selector.split.join(" "), body ] }
    end

    def serif?(body)
      body.match?(/font-family: var\(--serif\)|font: [^;]*var\(--serif\)|font: var\(--type-(?:voice|title)\)/)
    end

    def size_of(body)
      token = body[/font: var\(--type-(\w+)\)/, 1]
      value = token ? TOKENS.fetch(token.to_sym)[/ ([\d.]+(?:rem|px))/, 1] : body[/font(?:-size)?: (?:\d{3} )?([\d.]+(?:rem|px))/, 1]
      return unless value

      value.end_with?("rem") ? value.to_f * 16 : value.to_f
    end
end
