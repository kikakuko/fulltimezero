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

  # 2. 색은 CSS 만 — 그림에는 색값이 없다. path 의 fill 은 var() 로 바깥 CSS 의 값을
  # 받을 뿐이다(<use> 로 가리킬 때 사용자 지정 속성이 그림자 트리를 넘어 내려간다).
  test "e-fill 과 e-ink 의 색은 CSS 에서만 온다" do
    svg = SVG.read
    assert_no_match(/#\h{3,8}\b|rgba?\(|hsla?\(/, svg, "그림 파일에 색값이 박혀 있다")
    assert_no_match(/\s(?:stroke|style|color|stop-color)="/, svg, "그림 파일에 색 속성이 있다")
    fills = svg.scan(/\sfill="([^"]*)"/).flatten.uniq.sort
    assert_equal [ "url(#elephant-far-fade-ramp)", "var(--e-fill)", "var(--e-fill-far)", "var(--e-ink)", "var(--e-tusk)" ], fills

    doc = Nokogiri::XML(svg)
    doc.css("g[class^='elephant__']").reject { |g| g["class"] == "elephant__parts" }.each do |g|
      fill, ink = g.css("> path").map { |path| path["fill"] }
      expected = { "elephant__tusk" => "var(--e-tusk)", "elephant__leg-br" => "var(--e-fill-far)", "elephant__leg-bl" => "var(--e-fill-far)" }.fetch(g["class"], "var(--e-fill)")
      assert_equal expected, fill, "#{g['class']} 의 빛깔이 제 값을 받지 않는다"
      assert_equal "var(--e-ink)", ink
    end

    helper = Rails.root.join("app/helpers/elephant_helper.rb").read.lines.reject { |line| line.strip.start_with?("#") }.join
    assert_no_match(/#\h{3,8}\b|rgb\(|fill=|stroke/, helper, "들이는 쪽이 색을 넣는다")

    scripts = Rails.root.glob("app/javascript/**/*.js").map(&:read).select { |js| js.match?(/elephant|e-fill|e-ink/) }.join
    assert_no_match(/\.style\.(?:fill|stroke)|setAttribute\("(?:fill|stroke)"|--e-fill|--e-ink/, scripts, "스크립트가 코끼리에 색을 넣는다")

    css = CSS.read
    elephant = css[/\.elephant \{\s*display: block;[^}]*\}/m]
    assert_match(/--e-fill: color-mix\(in srgb, var\(--paper\)/, elephant)
    assert_match(/--e-ink: color-mix\(in srgb, var\(--night-deep\)/, elephant)
    assert_match(/--e-tusk: var\(--paper\);/, elephant, "상아가 한지빛이 아니다")
    assert_match(/\.elephant \.e-fill \{ fill: var\(--e-fill\); \}/, css)
    assert_match(/\.elephant \.e-ink \{ fill: var\(--e-ink\); \}/, css)
    assert_no_match(/\.elephant[^{]*\{[^}]*filter:\s*[^;]*brightness/m, css, "밝기 필터로 흰빛을 낸다 — 먹선까지 밝아진다")
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
      "tail-swing" => "4deg", "tail-period" => "3.7s" }.each do |name, value|
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

  # 아홉째(등지)는 형상이 풀리는 자리가 아니다. 흩어짐은 아홉 뒤의 문, 무위에만 있다.
  test "흩어짐은 무위에만 걸린다 — 앉기와 강원에는 없다" do
    Elephant::WINDOW_DAYS.times { |i| users(:one).rests.create!(rested_on: users(:one).today - i, duration: "a_while") }

    [ new_sitting_path, new_sitting_path, guide_chapter_path("abidings") ].each do |page|
      get page
      assert_no_match(/scatter|dispers|흩어/, Nokogiri::HTML(response.body).css(".elephant-field, .elephants").to_html,
                      "#{page} 의 코끼리에 흩어짐이 나타났다")
    end

    css = CSS.read.gsub(%r{/\*.*?\*/}m, "")
    css.scan(/([^{}]+)\{([^{}]*)\}/).each do |selector, body|
      next unless body.match?(/animation:\s*void-(?:part|ink|vanish)/)
      assert_match(/\.void__elephant/, selector, "무위 밖에서 흩어진다: #{selector.strip}")
    end
    assert_no_match(/elephant--scatter|elephant-drift|elephant-ink-loosen|elephant-fill-loosen/, css, "아홉째의 흩어짐이 남아 있다")
    assert_match(/--elephant-ink-white: 0\.3;/, css[/:root \{.*?\n\}/m], "흰 코끼리의 먹선 바닥이 없다")
  end

  # 강원의 코끼리 아홉은 그림 한 벌을 가리킨다 — 서 있으니 무리마다 CSS 가 닿을 일이 없다.
  test "강원 여섯째 장에는 코끼리 그림이 한 벌만 들어 있고, 아홉이 가리킨다" do
    get guide_chapter_path("abidings")
    html = response.body

    assert_equal 1, html.scan('class="elephant__body"').size, "그림이 여러 벌이다"
    assert_select ".elephants svg.elephant__defs #elephant-parts", count: 1
    assert_select ".elephants .elephant--used svg.elephant__art use[href='#elephant-parts']", count: 9
    assert_select ".elephants .elephant--walking-legs", false
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
