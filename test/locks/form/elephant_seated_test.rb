# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉은 코끼리의 결 — 바위 위의 몸(§2). docs/drawings/elephant_sitting.png 를 보고 손으로 그린 그림이다.
# 선 그림과 같은 무리 아홉(머리 안에 귀가 하나 더), 무리마다 축, 색은 변수만, 바위는 그리지 않는다.
# 걸어와 바위에 닿으면 선 그림이 앉은 그림으로 교차 페이드하고(3초 넘게), 앉은 뒤 뒤척이는 것은
# 귀 · 꼬리 · 코뿐이다 — 다리는 움직이지 않는다.
require "test_helper"

class ElephantSeatedTest < ActionDispatch::IntegrationTest
  SVG = Rails.root.join("app/assets/images/elephant_sitting.svg")
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  NINE = %w[body tail leg-br leg-bl leg-fr leg-fl trunk head tusk].freeze
  LEGS = %w[leg-fr leg-fl leg-bl leg-br].freeze

  test "앉은 코끼리는 아홉 그룹이 있고 다리 그룹에 애니메이션이 없다" do
    svg = Nokogiri::XML(SVG.read).remove_namespaces!
    groups = svg.css("g[class^='elephant__']").map { |g| g["class"].delete_prefix("elephant__") } - [ "parts", "ear" ]
    assert_equal NINE, groups, "무리 아홉이 그 이름 그 차례로 있지 않다"
    assert_equal 1, svg.css("g.elephant__head g.elephant__ear").size, "귀가 머리 안에 없다"

    svg.css("g[data-pivot]").each do |group|
      x, y = group["data-pivot"].split(",")
      assert_equal "transform-origin: #{x}px #{y}px", group["style"], "#{group["class"]} 의 축이 data-pivot 과 다르다"
    end

    css = CSS.read
    LEGS.each do |leg|
      css.scan(/([^{}]*\.elephant__#{leg}[^{}]*)\{([^{}]*)\}/).each do |selector, body|
        next unless body.include?("animation") && !body.include?("animation: none")

        assert_no_match(/elephant__art--seated/, selector, "앉은 코끼리의 #{leg} 에 움직임이 걸린다")
      end
    end
    assert_match(/\.elephant \.elephant__art--seated :is\(\.elephant__leg-fr, \.elephant__leg-fl, \.elephant__leg-bl, \.elephant__leg-br, [^)]*\) \{ animation: none; \}/, css,
      "앉은 코끼리의 다리가 선 코끼리의 뒤척임을 물려받는다")
    assert_match(/\.elephant--restless \.elephant__art--seated \.elephant__ear \{ animation: elephant-stir-head var\(--restless-period-head\)/, css,
      "앉은 뒤 귀가 뒤척이지 않는다")
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

  test "손으로 그린 그림이다 — 서른 path 안쪽, 이만 바이트 이하, 색은 변수만, 바위는 없다" do
    source = SVG.read

    assert_operator source.bytesize, :<=, 20_000, "그림이 #{source.bytesize} 바이트다"
    assert_operator source.scan("<path").size, :<=, 30, "path 가 서른을 넘는다 — 추적(trace)한 그림이다"
    assert_no_match(/#\h{3,6}\b|rgb\(|<image|base64/, source, "그림에 색값이나 래스터가 들어 있다")
    assert_no_match(/rock|바위/i, source, "그림에 바위를 그렸다 — 바위는 배경의 것이다")
    assert_match(/viewBox="0 0 250 283"/, source)
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
