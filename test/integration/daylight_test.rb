# This app is a raft. — 이 앱도 뗏목이다.
#
# 하루의 때 — 마당과 미륵당의 그림 위에 한 겹. 문 셋의 빛이 「다가오는 빛」이라면 이것은
# 「해가 있는 자리」다. 때는 문 셋과 같은 계산(GateLight)에서 오고, 화면이 열릴 때 한 번
# 정해진다. 때를 글자로 알리지 않고, 어떤 빛을 보았는지 어디에도 적지 않는다.
require "test_helper"

class DaylightTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  TIMES = %w[dawn day evening night].freeze

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "네 빛이 모두 따뜻하다 — 빨강이 파랑보다 낮지 않다" do
    TIMES.each do |time|
      red, _, blue = resolve("--daylight-#{time}")

      assert_operator red, :>=, blue, "#{time} 의 빛이 찬 쪽이다(#{format('#%02x%02x%02x', red, _, blue)})"
    end
  end

  test "네 빛과 옅기가 모두 :root 상수다" do
    TIMES.each do |time|
      assert_match(/--daylight-#{time}:\s*(?:var\(--|color-mix\()/, root, "#{time} 의 빛이 :root 의 밑색에서 나오지 않는다")
      assert_match(/--daylight-veil-#{time}:\s*[\d.]+;/, root, "#{time} 의 옅기가 :root 상수가 아니다")
    end

    rules = CSS.read.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]*\.daylight[^{}]*)\{([^{}]*)\}/)
    assert_equal 4, rules.size, "빛의 규칙은 밑틀 하나와 때 셋이다(낮은 밑틀 그대로)"
    rules.each do |selector, body|
      assert_no_match(/#\h{3,8}|rgba?\(/, body, "빛의 값이 규칙 안에 박혀 있다: #{selector.strip}")
      body.scan(/opacity:\s*([^;]+)/) do |value,|
        assert_match(/\Avar\(--daylight-veil-/, value.strip, "옅기가 규칙 안에 박혀 있다: #{selector.strip}")
      end
    end
  end

  test "마당과 미륵당에 한 겹이 얹히고, 때는 사용자의 시간대를 따른다" do
    @user.update!(time_zone: "Asia/Seoul")
    travel_to Time.zone.parse("2026-09-18 18:30:00 +0900") do
      get today_path
      assert_select ".compound__scene .daylight[data-light=evening][aria-hidden=true]", count: 1
      get days_path
      assert_select ".maitreya .daylight[data-light=evening]", count: 1
    end

    travel_to Time.zone.parse("2026-09-18 06:00:00 +0900") do
      get today_path
      assert_select ".daylight[data-light=dawn]", count: 1
    end
  end

  test "미륵이 솟는 장면에는 때의 빛이 닿지 않는다" do
    @user.clearings.destroy_all
    @user.update!(maitreya_seen_on: nil)

    get today_path
    scene = css_select("template[data-maitreya-target=scene]").first

    assert scene, "솟는 장면이 없다"
    assert_no_match(/daylight/, scene.to_html, "솟는 장면에 때의 빛이 얹혔다")
  end

  test "때를 글자로 알리지 않는다 — 빛은 속성으로만 간다" do
    views = Rails.root.glob("app/views/**/*.erb")
    views.each do |view|
      view.read.scan(/^.*gate_light.*$/) do |line|
        assert_match(/data-light="/, line, "#{view.basename} 이 때를 속성 밖으로 내보낸다: #{line.strip}")
      end
    end

    locales = Rails.root.glob("config/locales/*.yml").map(&:read).join
    assert_no_match(/daylight|새벽입니다|저녁입니다|밤입니다/, locales, "때를 알리는 글이 있다")

    get today_path
    assert_empty css_select(".daylight").map { |span| span.text.strip }.reject(&:empty?), "빛의 겹에 글이 있다"
  end

  private
    def root = CSS.read[/:root \{.*?\n\}/m]

    # color-mix(in srgb, var(--a) N%, var(--b)) 를 밑색까지 따라가 풀어 [r, g, b] 로.
    def resolve(token)
      value = root[/#{Regexp.escape(token)}:\s*([^;]+);/, 1].to_s.strip

      case value
      when /\A#(\h{6})\z/ then $1.scan(/../).map { |pair| pair.hex }
      when /\Avar\((--[\w-]+)\)\z/ then resolve($1)
      when /\Acolor-mix\(in srgb, var\((--[\w-]+)\) ([\d.]+)%, var\((--[\w-]+)\)\)\z/
        # 안쪽 resolve 가 $1 · $3 을 덮으므로 먼저 받아 둔다.
        first, share, second = $1, $2.to_f / 100, $3
        resolve(first).zip(resolve(second)).map { |a, b| (a * share + b * (1 - share)).round }
      else raise "풀지 못하는 값: #{token} = #{value}"
      end
    end
end
