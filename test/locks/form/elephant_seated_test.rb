# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉은 코끼리의 결 — 바위 위의 몸(§2). docs/drawings/elephant_sitting.png 의 윤곽을 뜬 그림이다.
# 무리는 다섯(몸통 · 귀 · 코 · 꼬리 · 상아) — 다리와 머리는 움직이지 않으므로 몸통 하나에 든다.
# 무리마다 축, 색은 변수만, 바위는 그리지 않는다. 걸어와 바위에 닿으면 선 그림이 앉은 그림으로
# 교차 페이드하고(3초 넘게), 앉은 뒤 뒤척이는 것은 귀 · 꼬리 · 코뿐이다.
require "test_helper"

class ElephantSeatedTest < ActionDispatch::IntegrationTest
  SVG = Rails.root.join("app/assets/images/elephant_sitting.svg")
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  FIVE = %w[body ear trunk tail tusk].freeze
  STILL = %w[body tusk].freeze
  STIRRING = %w[ear trunk tail].freeze

  test "앉은 코끼리는 무리 다섯이 있고 몸통 · 상아에 애니메이션이 없다" do
    svg = Nokogiri::XML(SVG.read).remove_namespaces!
    groups = svg.css("g[class^='elephant__']").map { |g| g["class"].delete_prefix("elephant__") } - [ "parts" ]
    assert_equal FIVE, groups, "무리 다섯이 그 이름 그 차례로 있지 않다"

    svg.css("g[data-pivot]").each do |group|
      x, y = group["data-pivot"].split(",")
      assert_equal "transform-origin: #{x}px #{y}px", group["style"], "#{group["class"]} 의 축이 data-pivot 과 다르다"
    end
    STIRRING.each { |part| assert svg.at_css("g.elephant__#{part}[data-pivot]"), "#{part} 에 축이 없다" }

    css = CSS.read
    STILL.each do |part|
      css.scan(/([^{}]*\.elephant__art--seated[^{}]*\.elephant__#{part}[^{}]*)\{([^{}]*)\}/).each do |selector, body|
        assert_no_match(/animation:(?! none)/, body, "앉은 코끼리의 #{part} 에 움직임이 걸린다 — #{selector.strip}")
      end
    end
    assert_match(/\.elephant \.elephant__art--seated :is\(\.elephant__body, \.elephant__tusk\) \{ animation: none; \}/, css,
      "앉은 코끼리의 몸통 · 상아가 선 코끼리의 뒤척임을 물려받는다")
    assert_match(/\.elephant--restless \.elephant__art--seated \.elephant__ear \{ animation: elephant-stir-head var\(--restless-period-head\)/, css,
      "앉은 뒤 귀가 뒤척이지 않는다")
    %w[trunk tail].each do |part|
      assert_match(/\.elephant--restless \.elephant__#{part} \{ animation: elephant-stir-#{part} /, css, "앉은 뒤 #{part} 가 뒤척이지 않는다")
    end
  end

  test "교차 페이드는 3초 이상이고, 움직임을 줄이면 바로 바뀐다" do
    css = CSS.read

    seat = css[/:root \{.*?\n\}/m][/--elephant-seat-time: ([\d.]+)s;/, 1].to_f
    assert_operator seat, :>=, 3.0, "교차 페이드가 3초보다 짧다(#{seat})"
    assert_match(/\.elephant__art--standing, \.elephant__art--seated \{ transition: opacity var\(--elephant-seat-time\) linear; \}/, css,
      "두 그림이 같은 시간 · 같은 곡선으로 엇갈리지 않는다 — 둘 다 보이거나 둘 다 안 보이는 때가 생긴다")
    assert_match(/\.elephant--seated \.elephant__art--standing \{ opacity: 0; \}/, css)
    assert_match(/\.elephant--seated \.elephant__art--seated \{ opacity: 1; \}/, css)
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.elephant__art--standing, \.elephant__art--seated \{ transition: none; \}/, css)
  end

  test "윤곽을 뜬 그림이다 — 오만 바이트 이하, 색은 변수만, 바위는 없다" do
    source = SVG.read

    assert_operator source.bytesize, :<=, 50_000, "그림이 #{source.bytesize} 바이트다"
    assert_no_match(/#\h{3,6}\b|rgb\(|<image|base64/, source, "그림에 색값이나 래스터가 들어 있다")
    assert_no_match(/rock|바위/i, source, "그림에 바위를 그렸다 — 바위는 배경의 것이다")
    assert_match(/viewBox="0 0 250 268"/, source)
    assert_match(%r{aspect-ratio: 250 / 268;}, CSS.read, "앉은 그림의 틀이 viewBox 와 달라 발끝이 바닥선에서 뜬다")
  end

  test "선방에서는 두 그림이 같은 자리에 겹치고, 앉는 중에는 처음부터 앉아 있다" do
    sign_in_as users(:one)

    get new_sitting_path
    assert_select ".elephant-place .elephant:not(.elephant--seated) svg.elephant__art--standing", count: 1
    assert_select ".elephant-place .elephant svg.elephant__art--seated[aria-hidden=true]", count: 1

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select ".elephant-place .elephant.elephant--seated svg.elephant__art--seated", count: 1
  end
end
