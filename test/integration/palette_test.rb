# This app is a raft. — 이 앱도 뗏목이다.
#
# 색 (SPIRIT §2). 사찰에서 빌려 온다 — 한지 · 먹 · 주사 · 단청.
#
# 이 파일이 지키는 것:
#   색은 한 곳에만 있다        — application.css 의 :root 밖에 색 값이 없다
#   어둠은 문의 것이다        — 문 셋과 몰입 화면만 어둡고, 기기 다크 모드를 따르지 않는다
#   주사는 하루에 한 번       — 방금 올린 한 자에만. 버튼 · 링크 · 오류에는 없다
#   셋째 문은 밝아지며 열린다 — 어둠이 한지빛이 되고 그대로 오늘로
#   매일의 문은 어두워졌다 밝아지며 걷힌다
#   문에는 이름이 없다        — 형상으로만. 둘째 문 양쪽의 자리는 비어 있다
require "test_helper"
require_relative "../test_helpers/copy_locks"

class PaletteTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  COLOR = /#\h{3,8}\b|\b(?:rgba?|hsla?|oklch|oklab|lab|lch)\(/

  # 주사(朱砂)를 쓸 수 있는 자리 — 탑 안의 「오늘 쓴 한 자」 하나뿐이다(§2 하루 한 번).
  CINNABAR_PLACES = [ ".pagoda__today path" ].freeze

  # 석간주(石間硃)를 쓸 수 있는 자리 — 탑 그림의 클래스뿐이다. 건물의 색이라 §2 와 상관없다.
  SEOKGANJU_PLACES = /\A\.pagoda__(?:wash|pillar|under|eave|eave-light|eave-shade|base|base-shade|finial|ring|mast|jewel)\z/

  # 주사가 결코 닿아서는 안 되는 것.
  NEVER_RED = /\b(?:a|button|input|select|textarea|label)\b|\.(?:action|quiet|plain|flash|errors|notice|alert|door)\b/

  # 어두운 자리 — 처음의 문 셋(그림의 어둠) · 매일의 문 · 앉는 중 · 무위.
  DARK_PLACES = %w[.gates .daily-door .night .void].freeze

  test "색 값은 :root 한 곳에만 있다" do
    root, rest = palette_and_rest

    assert_match(/--paper:/, root)
    assert_match(/--ink:/, root)
    %w[--cinnabar --seokganju-deep --seokganju-hi --seokganju-shadow --gilt].each { |token| assert_match(/#{token}:/, root) }
    assert_match(/--dancheong-green:/, root)
    assert_match(/--dancheong-ocher:/, root)

    strays = rest.lines.each_with_index.select { |line, _| line.match?(COLOR) }
    assert_empty strays.map { |line, n| "#{n}: #{line.strip}" }, ":root 밖에 색 값이 흩어져 있다"
  end

  test "화면과 스크립트에는 색 값이 없다" do
    files = Dir[Rails.root.join("app/{views,javascript,helpers,components}/**/*.{erb,rb,js}")]
    files -= [ Rails.root.join("app/views/pwa/manifest.json.erb").to_s ]

    offenders = files.select { |file| File.read(file).match?(COLOR) }
    assert_empty offenders.map { |file| file.delete_prefix("#{Rails.root}/") }
  end

  # 설치된 앱의 바탕도 한지다. 매니페스트는 CSS 변수를 읽지 못하므로
  # 값을 적되, :root 의 한지와 어긋나지 않게 묶는다.
  test "앱 매니페스트의 바탕은 한지와 같은 색이다" do
    paper = palette_and_rest.first[/--paper:\s*(#\h+)/, 1]
    manifest = JSON.parse(Rails.root.join("app/views/pwa/manifest.json.erb").read)

    assert_equal paper, manifest["background_color"]
    assert_equal paper, manifest["theme_color"]
  end

  test "기기의 다크 모드를 따라 앱 전체를 어둡게 하지 않는다" do
    assert_no_match(/prefers-color-scheme/, CSS.read)

    get threshold_path
    assert_select "meta[name=color-scheme][content=light]"
  end

  test "어둠은 문과 몰입 화면의 것이고, 나머지는 한지 위에 있다" do
    assert_equal "var(--paper)", declaration("body", "background")

    DARK_PLACES.each do |place|
      assert_match(/\Avar\(--night/, declaration(place, "background").to_s, "#{place} 가 어둡지 않다")
    end
  end

  # 1. 주사는 탑 안의 오늘 쓴 한 자에만 — 버튼 · 글꼴 · 테두리 · 아이콘 어디에도 없다.
  test "주사가 쓰인 곳은 탑 안의 오늘 쓴 한 자 하나뿐이다" do
    uses = rules.select { |_, body| body.match?(/var\(--cinnabar\)/) }.flat_map { |selector, _| selector.split(",").map(&:strip) }

    assert_equal CINNABAR_PLACES, uses, "주사가 오늘의 한 자 밖에 쓰였다: #{uses - CINNABAR_PLACES}"
    uses.each { |one| assert_no_match NEVER_RED, one, "주사가 버튼 · 링크 · 오류에 닿았다" }

    elsewhere = Rails.root.glob("app/{views,javascript,helpers}/**/*.{erb,js,rb}").select { |file| file.read.include?("--cinnabar") }
    assert_empty elsewhere.map { |file| file.relative_path_from(Rails.root).to_s }, "화면이나 스크립트가 주사를 직접 칠한다"
  end

  # 2. 탑 그림은 석간주 — 주사가 닿으면 걸린다.
  test "탑 그림에는 석간주만 — 주사가 닿지 않는다" do
    rules.each do |selector, body|
      selector.split(",").map(&:strip).each do |one|
        if body.match?(/var\(--seokganju-/)
          assert_match SEOKGANJU_PLACES, one, "석간주가 탑 그림 밖에 쓰였다: #{one}"
        end
        if one.match?(SEOKGANJU_PLACES)
          assert_no_match(/--cinnabar/, body, "탑 그림에 주사가 닿았다: #{one}")
        end
      end
    end
  end

  # 3. 어제 이전의 글씨는 먹이다 — 오늘의 한 자만 today 로 실린다.
  test "어제 이전의 글씨에는 주사가 닿지 않는다" do
    css = CSS.read
    assert_no_match(/\.pagoda__(?:ink|fresh|settling)[^{]*\{[^}]*--cinnabar/, css, "어제의 글씨도 붉다")
    assert_match(/\.pagoda__ink path \{ fill: var\(--ink\); \}/, css)

    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read
    assert_match(/cell\.today && "pagoda__today"/, scene, "주사가 오늘의 한 자에 매이지 않았다")
    assert_equal 1, scene.scan(/"pagoda__today"/).size

    user = users(:one)
    heart_sutra.chars.where(pos: 1..2).each do |char|
      user.copyings.create!(sutra_char: char, copied_on: user.today - (3 - char.pos), glyph_paths: [ [ [ 0.5, 0.5 ] ] ])
    end
    today = user.copyings.create!(sutra_char: user.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    cells = PagodaLayout.scene(user.copyings.includes(:sutra_char), today: user.today)[:cells]
    assert_equal [ false, false, true ], cells.map { |cell| cell[:today] }
    assert_equal today.sutra_char.pos, cells.find { |cell| cell[:today] }[:pos]

    travel 1.day do
      cells = PagodaLayout.scene(user.copyings.includes(:sutra_char), today: user.today)[:cells]
      assert_empty cells.select { |cell| cell[:today] }, "어제의 주사가 마르지 않는다"
    end
  end

  # 4. 그림 파일에는 색이 없다.
  test "탑 그림 파일 안에 # 으로 시작하는 색이 없다" do
    art = Rails.root.join("app/assets/images/pagoda.svg").read
    assert_no_match(/#\h{3,8}\b|\s(?:fill|stroke|opacity|style)="/, art, "탑 그림에 색이나 옅기가 박혀 있다")
    assert_not Rails.root.join("app/assets/images/pagoda_cinnabar.svg").exist?, "그림 이름에 색이 붙어 있다"
    assert_not Rails.root.join("app/assets/images/pagoda_outline.svg").exist?, "옛 윤곽이 남아 있다"
  end

  # 한 자는 하루에 한 번만 올라가므로, 붉은 자는 하루에 하나를 넘지 않는다.
  test "탑의 장면에 방금 올린 자는 하나뿐이다" do
    user = users(:one)
    rows = heart_sutra.chars.where(pos: 1..2).map do |char|
      { user_id: user.id, sutra_char_id: char.id, copied_on: user.today - (3 - char.pos),
        glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
    end
    Copying.insert_all!(rows)
    fresh = user.copyings.create!(sutra_char: user.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    cells = PagodaLayout.scene(user.copyings.includes(:sutra_char), fresh: fresh)[:cells]
    assert_equal 3, cells.size
    assert_equal 1, cells.count { |cell| cell[:fresh] }
  end

  # 문을 나서는 순간은 어둠에서 밝음으로 넘어가는 것으로 보인다(SPIRIT §2).
  test "셋째 문은 장막이 걷히고, 그림이 한지빛 오늘로 옅어지며 열린다" do
    assert_match(/\.gates\.gates--leaving \{ opacity: 0; /, CSS.read)
    assert_equal "var(--paper)", declaration("body", "background"), "그림이 옅어진 자리가 한지가 아니다"

    breath = Rails.root.join("app/javascript/controllers/breath_controller.js").read
    assert_match(/gates--leaving"\)\s*await settle\(this\.gates, LEAVE\)\s*this\.gateTarget\.requestSubmit\(\)/, breath,
                 "옅어짐이 끝나기 전에 문이 넘어간다")
  end

  # 첫째 문의 빛을 짧게 줄인 장면이다. 빛이 가라앉은 뒤에 문 전체가 옅어진다.
  test "매일의 문은 빛이 다가와 가라앉은 뒤 옅어지며 걷힌다" do
    css = CSS.read

    assert_match(/@keyframes daily-door \{ from \{ opacity: 1 \} to \{ opacity: 0 \} \}/, css)
    assert_match(/animation: daily-door [\d.]+s ease-in var\(--light-daily\) forwards;/, css, "빛이 가라앉기 전에 걷힌다")
    assert_match(/\.daily-door \.gates__light \{ animation: gate-light var\(--light-daily\)/, css)
    assert_match(/\.daily-door \.gates__flood \{ animation: gate-flood var\(--light-daily\)/, css)
  end

  # 문의 이름은 글로 붙이지 않는다 — 현판으로만 건다. 현판은 설명이 아니라
  # 건축이고(실제 일주문의 편액), 옛 이름이라 인용 원문 예외(§5) 아래 있다.
  # 그러니 이름은 현판 안에만, 한자 한 줄과 읽기 한 줄뿐이다. 뜻풀이도 순서도 없다.
  test "문의 이름은 현판에만 있다 — 글에도, 뜻풀이에도, 순서에도 없다" do
    names = CopyLocks.pattern(:gate_names)
    sign_in_as users(:one)

    I18n.available_locales.each do |locale|
      [ threshold_path(locale: locale), threshold_naming_path(locale: locale), threshold_breath_path(locale: locale) ].each do |door|
        get door
        page = Nokogiri::HTML(response.body)

        page.css(".gate-plaque").each do |plaque|
          parts = plaque.css(".gate-plaque__board, .gate-plaque__reading").map { |part| part.text.strip }
          assert_equal parts.join(" "), plaque.text.split.join(" "), "현판에 한자와 읽기 말고 다른 것이 있다"
          assert_match(/\A\p{Han}{3}\z/, parts.first, "현판의 한자가 옛 이름 세 자가 아니다")
          assert_no_match(/\d|제.문|첫째|둘째|셋째|first|second|third|\//i, plaque.text, "현판에 순서가 적혔다")
          assert_operator parts.last.split.size, :<=, 5, "읽기가 뜻풀이가 되었다: #{parts.last}"
        end

        page.css(".gate-plaque").each(&:remove)
        assert_no_match names, page.css("body").text, "#{door} 의 현판 밖에 문의 이름이 있다"
      end
    end
  end

  test "현판은 지금 선 문의 것만 보인다" do
    css = CSS.read

    %w[stop naming breath].each do |door|
      assert_match(/\.gates__veil\[data-state="#{door}"\] ~ \.gate-plaque--#{door}/, css)
    end
    assert_match(/\.gate-plaque \{[^}]*opacity: 0;/, css, "현판이 처음부터 모두 보인다")
    assert_no_match(/\.gates__veil\[data-state="(\w+)"\] ~ \.gate-plaque--(?!\1)\w+/, css, "먼 문에 현판이 걸린다")

    # 빛이 그 문에 닿을 때 0.6초에 걸쳐 — 첫째 문은 빛이 발밑에 닿는 2.6초(3.8초의 0.6842).
    assert_match(/\.gate-plaque--stop \{ animation: plaque-rise 0\.6s ease-out calc\(var\(--light-arrive\) \* 0\.6842\) both; \}/, css)
    assert_match(/\.daily-door \.gate-plaque--stop \{ animation: plaque-rise 0\.6s ease-out calc\(var\(--light-daily\) \* 0\.6842\) both; \}/, css)
    { "stop" => [ 566, 1 ], "naming" => [ 300, 0.62 ], "breath" => [ 126, 0.42 ] }.each do |door, (y, scale)|
      assert_match(/\.gate-plaque--#{door} \{ --plaque-y: #{y}; --plaque-scale: #{scale}; \}/, css)
    end
  end

  # 둘째 문(천왕문)의 사천왕 둘 — 그림 안의 인물이지 앱의 도상이 아니다.
  # 이름을 적지 않고, 둘째 문에서만 장막이 걷히는 대로 드러난다. 문 셋의 그림이라
  # 움직이지 않는다 — 도상의 규칙(말하지 않는다)이 아니라 문의 규칙이다.
  test "사천왕은 둘째 문을 사이에 두고 서고, 이름도 움직임도 없다" do
    sign_in_as users(:one)

    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door

      assert_select "#gates .gates__frame .gates__kings img.gates__king[alt='']", count: 2
      assert_select "#gates .gates__king--left[src*=four_king_left]", count: 1
      assert_select "#gates .gates__king--right[src*=four_king_right]", count: 1
      assert_no_match(/사천왕|증장|다문|광목|지국|천왕(?!문)|Four Kings(?! ?\z)|Virūḍhaka|Vaiśravaṇa/,
                      Nokogiri::HTML(response.body).tap { |page| page.css(".gate-plaque").each(&:remove) }.css("body").text,
                      "#{door} 에 사천왕의 이름이 적혔다")
    end
    assert_select ".threshold__flank", false

    css = CSS.read
    kings = css[/\.gates__kings \{[^}]*\}/m]
    assert_match(/--kings-height: 116;/, kings)
    assert_match(/--kings-feet: 300;/, kings)
    assert_match(/--kings-apart: 52;/, kings)
    assert_match(/opacity: 0; transition: opacity 1\.2s ease-out;/, kings, "장막이 걷히는 것과 같은 때가 아니다")
    assert_match(/\.gates__frame:has\(\.gates__veil\[data-state="naming"\]\) \.gates__kings \{ opacity: 1; \}/, css)
    assert_no_match(/\.gates__veil\[data-state="(?:stop|breath|open)"\]\) \.gates__kings/, css, "둘째 문 밖에서 드러난다")

    css.scan(/([^{}]*\.gates__king[^{}]*)\{([^{}]*)\}/).each do |selector, body|
      assert_no_match(/animation|filter|drop-shadow|box-shadow|rotate|scale/, body, "사천왕이 움직이거나 빛난다: #{selector.strip}")
    end
  end

  test "사천왕은 한 장에서 나눠 자르고, 가장자리에서 이어진 바탕만 걷는다" do
    %w[left right].each do |side|
      png = Rails.root.join("app/assets/images/four_king_#{side}.png").binread
      width, height = png.byteslice(16, 8).unpack("NN")

      assert_equal 6, png.byteslice(25, 1).unpack1("C"), "#{side} 가 RGBA 가 아니다"
      assert_in_delta 0.492, width / height.to_f, 0.01
    end

    knockout = Rails.root.join("bin/knockout").read
    assert_match(/--region=0\.163,0\.283,0\.192,0\.585 --connected/, knockout, "자르는 값이 기록되어 있지 않다")
    assert Rails.root.join("app/assets/images/four_kings.png").exist?
  end

  private
    def palette_and_rest
      css = CSS.read.gsub(%r{/\*.*?\*/}m, "")
      root = css[/:root \{.*?\n\}/m]

      [ root, css.sub(root, "") ]
    end

    # 가장 안쪽 규칙들 — [선택자, 본문]. @media 안의 규칙도 함께.
    def rules
      CSS.read.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]+)\{([^{}]*)\}/).map { |selector, body| [ selector.strip, body ] }
    end

    # 그 선택자가 홀로 또는 묶여 선 규칙들 가운데 그 속성을 처음 적은 값.
    def declaration(selector, property)
      pattern = /(?:\A|[;\s])#{Regexp.escape(property)}:\s*([^;]+?)\s*(?:;|\z)/

      rules.filter_map { |one, body| body[pattern, 1] if one.split(",").map(&:strip).include?(selector) }.first
    end
end
