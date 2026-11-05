# This app is a raft. — 이 앱도 뗏목이다.
#
# 그림 도구의 결 — 바깥 AI 는 그림을 만드는 연장일 뿐이다. 앱은 부르지 않는다(STATUS 4절, 2026-11-04).
# 도구는 script/art/ 에만 있고, 앱이 실행 중에 싣는 자리(app/ · config/ · lib/) 어디서도 그것을
# 부르지 않는다. 도구는 Ruby 표준 라이브러리만 쓰고(새 젬 0), 열쇠는 .env.art 에서만 읽으며, 열쇠
# 파일과 생성물 원본은 저장소에 들지 않는다. 바깥을 부르지 않는다는 약속 자체는 spirit_promise_test ·
# outward_call_test 가 지킨다 — 여기서는 연장이 앱 안으로 새어 들지 않는 결을 본다.
require "test_helper"

class ArtToolTest < ActiveSupport::TestCase
  TOOL = Rails.root.join("script/art")
  APP_PLACES = %w[app config lib].freeze
  # 표준 라이브러리 — 도구가 require 할 수 있는 것.
  STDLIB = %w[json net/http uri base64 fileutils].freeze

  test "앱이 싣는 자리 어디서도 그림 도구를 부르지 않는다" do
    offenders = APP_PLACES.flat_map { |place| Rails.root.glob("#{place}/**/*.{rb,erb,yml,js}") }.select do |file|
      file.read.match?(%r{script/art|monorouter|MonoRouter|\.env\.art|MONOROUTER}i)
    end

    assert_empty offenders.map { |file| file.relative_path_from(Rails.root).to_s },
      "앱 안에서 그림 도구 · MonoRouter · 그 열쇠를 가리킨다 — 연장은 앱 밖에 있어야 한다"
    assert_not_includes Rails.application.config.autoload_paths.map(&:to_s) + Rails.application.config.eager_load_paths.map(&:to_s),
      TOOL.to_s, "그림 도구가 앱의 자동 로딩 길에 들었다"
  end

  test "도구는 표준 라이브러리만 쓰고, 서로만 부른다" do
    files = TOOL.glob("*.rb")
    assert_not_empty files

    files.each do |file|
      source = file.read
      requires = source.scan(/^\s*require\s+["']([^"']+)["']/).flatten
      assert_empty requires - STDLIB, "#{file.basename} 이 표준 라이브러리 밖의 것을 부른다"
      source.scan(/^\s*require_relative\s+["']([^"']+)["']/).flatten.each do |relative|
        assert TOOL.join("#{relative}.rb").exist?, "#{file.basename} 이 script/art 밖의 것을 부른다: #{relative}"
      end
      assert_match(/\A# This app is a raft\. — 이 앱도 뗏목이다\./, source)
    end
  end

  test "열쇠는 .env.art 에서만 읽고, 찍지 않는다" do
    source = TOOL.join("monorouter.rb").read

    assert_match(/ENV_FILE = File\.join\(ROOT, "\.env\.art"\)/, source)
    assert_no_match(/ENV\[|ENV\.fetch/, source, "열쇠를 환경 변수에서 읽는다 — .env.art 에서만")
    TOOL.glob("*.rb").each do |file|
      code = file.read.gsub(/^\s*#.*$/, "")
      assert_no_match(/^\s*(?:puts|print|pp?|warn|\$stdout\.write|\$stderr\.write)\b[^\n]*\bkey\b/, code, "#{file.basename} 에 열쇠를 찍는 줄이 있다")
    end
    assert_no_match(/key_preview/, source.gsub(/^\s*#.*$/, ""), "응답의 키 미리보기를 읽는다")
    # 오류에는 길 · 상태 · 본문(열쇠는 가린다)만, 요청 헤더는 없다.
    assert_match(/raise Error, "#\{req\.method\} #\{req\.uri\.path\} → #\{res\.code\} #\{hide\(res\.body\)/, source)
    assert_no_match(/req\.(?:to_hash|each_header|\[\]\("Authorization"\))|req\["Authorization"\](?!\s*=)/, source, "요청 헤더를 꺼낸다")
  end

  test "열쇠 파일과 생성물 원본은 저장소에 들지 않는다" do
    ignored = ->(path) { system("git", "check-ignore", "-q", path, chdir: Rails.root.to_s) }

    assert ignored.call(".env.art"), ".env.art 가 git 에서 무시되지 않는다"
    assert ignored.call("tmp/art/x.jpeg"), "tmp/art/ 가 git 에서 무시되지 않는다"
    assert_match(%r{^/\.env\*}, Rails.root.join(".dockerignore").read, ".env.art 가 배포 이미지에 실린다")
  end

  test "예산과 한 번의 장 수는 도구 안의 상수다" do
    source = TOOL.join("monorouter.rb").read

    assert_match(/BUDGET = 30_000/, source)
    assert_match(/MOST_PER_RUN = 4/, source)
    assert_match(/def draw\(.*?\n\s*before = check_budget!/m, source, "부르기 전에 예산을 보지 않는다")
  end
end
