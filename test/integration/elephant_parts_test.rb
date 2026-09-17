# This app is a raft. — 이 앱도 뗏목이다.
#
# 부위별 코끼리 — elephant_parts.svg 의 무리 아홉이 제 차례로 겹치고, 색은 CSS 가
# --ele 하나로 칠하고, 다리는 어긋난 짝으로 걷는다. 도상은 말하지 않는다 —
# 걷는 것은 말하는 것이 아니다. 다만 곁에 숫자 · 이름 · 「지금 여기」가 없다.
require "test_helper"

class ElephantPartsTest < ActionDispatch::IntegrationTest
  SVG = Rails.root.join("app/assets/images/elephant_parts.svg")
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  PARTS = %w[body tail leg-br leg-bl leg-fr leg-fl trunk head tusk].freeze
  PIVOTS = { "leg-fr" => [ 133, 125 ], "leg-fl" => [ 157, 125 ], "leg-bl" => [ 273, 125 ], "leg-br" => [ 297, 125 ],
             "trunk" => [ 53, 101 ], "tail" => [ 333, 109 ], "head" => [ 95, 84 ] }.freeze

  setup do
    sign_in_as users(:one)
    nine_abidings
  end

  # 1. 무리 아홉이 이름 그대로, 그 차례로 — 차례가 곧 겹치는 차례다.
  test "SVG 의 무리 아홉이 이름 그대로, 그 차례로 있다" do
    doc = Nokogiri::XML(SVG.read)
    groups = doc.css("g[class^='elephant__']").map { |g| g["class"].delete_prefix("elephant__") } - [ "parts" ]

    assert_equal PARTS, groups
    doc.css("g[class^='elephant__']").reject { |g| g["class"] == "elephant__parts" }.each do |g|
      assert_equal %w[e-fill e-ink], g.css("> path").map { |path| path["class"] }, "#{g['class']} 의 한 쌍이 아니다"
    end
    assert_equal %w[leg-br leg-bl], doc.css("g[data-depth=far]").map { |g| g["class"].delete_prefix("elephant__") }
    PIVOTS.each do |part, (x, y)|
      assert_equal "#{x},#{y}", doc.at_css("g.elephant__#{part}")["data-pivot"]
    end
    assert_not Rails.root.join("app/assets/images/elephant.png").exist?, "통짜 그림이 남아 있다"
  end

  # 2. 색은 CSS 만 — 그림 파일에도, 들이는 쪽에도, 스크립트에도 색이 없다.
  test "e-fill 과 e-ink 의 색은 CSS 에서만 온다" do
    svg = SVG.read
    assert_no_match(/\s(?:fill|stroke|style|color|stop-color)="/, svg, "그림 파일에 색이 박혀 있다")

    helper = Rails.root.join("app/helpers/elephant_helper.rb").read
    assert_no_match(/fill|stroke|#\h{3,8}\b|rgb\(/, helper, "들이는 쪽이 색을 넣는다")

    scripts = Rails.root.glob("app/javascript/**/*.js").map(&:read).select { |js| js.match?(/elephant|e-fill|e-ink/) }.join
    assert_no_match(/\.style\.(?:fill|stroke)|setAttribute\("(?:fill|stroke)"|e-fill|e-ink/, scripts, "스크립트가 코끼리에 색을 넣는다")

    css = CSS.read
    %w[e-fill e-ink].each do |part|
      rule = css[/\.elephant \.#{part} \{[^}]*\}/m]
      assert_match(/fill: color-mix\(in srgb, var\(--/, rule)
    end
    assert_no_match(/\.elephant[^{]*\{[^}]*filter:\s*[^;]*brightness/m, css, "밝기 필터로 흰빛을 낸다 — 먹선까지 밝아진다")
    assert_match(/\.elephant \.elephant__tusk \.e-fill \{ fill: var\(--paper\); \}/, css, "상아가 한지빛이 아니다")
  end

  # 3. 다리 넷(과 코 · 꼬리 · 머리)의 축은 그림의 data-pivot 이다.
  test "무리의 transform-origin 이 data-pivot 과 같다" do
    css = CSS.read

    assert_match(/\.elephant__art g \{ transform-box: view-box; \}/, css)
    PIVOTS.each do |part, (x, y)|
      assert_match(/\.elephant__#{part} \{ transform-origin: #{x}px #{y}px; \}/, css, "#{part} 의 축이 그림과 다르다")
    end
  end

  # 4. 어긋난 짝 — (앞오른, 뒤왼)과 (앞왼, 뒤오른)이 반 주기 어긋난다.
  test "(leg-fr, leg-bl)과 (leg-fl, leg-br)이 반 주기 어긋난다" do
    css = CSS.read

    one = css[/\.elephant--walking-legs \.elephant__leg-fr,\s*\.elephant--walking-legs \.elephant__leg-bl \{ animation: ([^;]+); \}/, 1]
    two = css[/\.elephant--walking-legs \.elephant__leg-fl,\s*\.elephant--walking-legs \.elephant__leg-br \{ animation: ([^;]+); \}/, 1]

    assert_equal "elephant-leg var(--elephant-stride) ease-in-out infinite", one
    assert_equal "elephant-leg var(--elephant-stride) ease-in-out calc(var(--elephant-stride) / -2) infinite", two
    root = css[/:root \{.*?\n\}/m]
    { "stride" => "1.8s", "leg-swing" => "5deg", "bob" => "1.5px", "trunk-swing" => "3deg", "trunk-period" => "2.9s",
      "tail-swing" => "4deg", "tail-period" => "3.7s", "scatter" => "3s" }.each do |name, value|
      assert_match(/--elephant-#{name}: #{Regexp.escape(value)};/, root, "--elephant-#{name} 가 :root 상수가 아니다")
    end
    assert_match(/elephant-bob calc\(var\(--elephant-stride\) \/ 2\)/, css, "몸통이 다리의 두 배 빠르기로 오르내리지 않는다")
  end

  # 5. 움직임을 줄이면 어떤 무리에도 animation 이 걸리지 않는다.
  test "움직임을 줄이면 어떤 무리에도 animation 이 걸리지 않는다" do
    rules_with_media(CSS.read).each do |selector, body, media|
      next unless selector.match?(/elephant__(?:body|tail|leg|trunk|head|tusk|parts)|\.e-fill|\.e-ink|elephant__art g|g\[class\^="elephant__"\]/)
      next unless body.match?(/animation:(?!\s*none\s*;)/)

      assert_includes media.to_s, "prefers-reduced-motion: no-preference", "움직임을 줄여도 돈다: #{selector}"
    end
  end

  # 6. 코끼리 무리 안에 텍스트 노드가 없다 — 곁에 숫자도 이름도 없다.
  test "코끼리 무리 안에 텍스트 노드가 없고, 곁에 숫자 · 이름 · 「지금 여기」가 없다" do
    [ new_sitting_path, guide_chapter_path("abidings") ].each do |page|
      get page
      doc = Nokogiri::HTML(response.body)

      doc.css(".elephant").each do |elephant|
        texts = elephant.xpath(".//text()").map(&:text).reject { |text| text.strip.empty? }
        assert_empty texts, "#{page} 의 코끼리 안에 글이 있다"
        assert_empty elephant.css("text, title, desc"), "#{page} 의 코끼리에 글 요소가 있다"
      end
      doc.css(".elephant-place, .elephants").each do |holder|
        assert_no_match(/\d|지금 여기|you are here/i, holder.text.strip, "#{page} 의 코끼리 곁에 표시가 붙었다")
      end
    end
  end

  # 형상을 잃는 것은 흩어지는 것이다 — 한 번 흩어지면 되돌아오지 않는다.
  test "흩어짐은 먹선이 먼저, 빛깔이 나중에 풀리고 다시 모이지 않는다" do
    css = CSS.read

    assert_match(/@keyframes elephant-drift \{ to \{ translate:/, css)
    assert_match(/@keyframes elephant-ink-loosen \{ 0% \{ opacity: 1; \} 55% \{ opacity: var\(--elephant-scatter-ink\); \}/, css)
    assert_match(/@keyframes elephant-fill-loosen \{ 0%, 40% \{ opacity: 1; \}/, css)
    css.scan(/animation: elephant-(?:drift|ink-loosen|fill-loosen)[^;]*;/).each do |animation|
      assert_match(/forwards;\z/, animation, "흩어진 뒤 제자리로 돌아온다")
      assert_no_match(/infinite|alternate/, animation, "흩어짐이 되풀이된다")
    end
    PARTS.each { |part| assert_match(/\.elephant__#{part} \{ --dx: -?\d+px; --dy: -?\d+px; \}/, css, "#{part} 가 밀리는 쪽이 없다") }
  end

  private
    # [선택자, 본문, 감싼 @media 머리] — 중괄호 깊이를 따라 어느 @media 안인지 가린다.
    def rules_with_media(css)
      css = css.gsub(%r{/\*.*?\*/}m, "")
      rules = []
      stack = []
      head = +""
      css.each_char do |char|
        case char
        when "{"
          if head.strip.start_with?("@")
            stack << head.strip
          else
            stack << [ :rule, head.strip, +"" ]
          end
          head = +""
        when "}"
          top = stack.pop
          if top.is_a?(Array)
            media = stack.reverse.find { |item| item.is_a?(String) && item.start_with?("@media") }
            rules << [ top[1], top[2], media ]
          end
          head = +""
        else
          if stack.last.is_a?(Array)
            stack.last[2] << char
          else
            head << char
          end
        end
      end
      rules
    end
end
