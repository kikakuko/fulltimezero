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

  # 주사를 쓸 수 있는 자리. 미륵이 올라오는 순간이 생기면 여기에 더한다.
  CINNABAR_PLACES = [ /\A\.pagoda__fresh\b/ ].freeze

  # 주사가 결코 닿아서는 안 되는 것.
  NEVER_RED = /\b(?:a|button|input|select|textarea|label)\b|\.(?:action|quiet|plain|flash|errors|notice|alert|door)\b/

  # 어두운 자리 — 처음의 문 셋(그림의 어둠) · 매일의 문 · 앉는 중 · 무위.
  DARK_PLACES = %w[.gates .daily-door .night .void].freeze

  test "색 값은 :root 한 곳에만 있다" do
    root, rest = palette_and_rest

    assert_match(/--paper:/, root)
    assert_match(/--ink:/, root)
    assert_match(/--cinnabar:/, root)
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

  test "주사는 방금 올린 한 자에만 쓴다" do
    uses = rules.select { |_, body| body.include?("var(--cinnabar)") }

    assert_not_empty uses, "주사가 어디에도 없다"
    uses.each do |selector, _|
      selector.split(",").map(&:strip).each do |one|
        assert CINNABAR_PLACES.any? { |place| one.match?(place) }, "주사가 #{one} 에 쓰였다"
        assert_no_match NEVER_RED, one, "주사가 버튼 · 링크 · 오류에 닿았다"
      end
    end

    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read
    assert_match(/cell\.fresh && "pagoda__fresh"/, scene, "주사가 방금 올린 자에 매이지 않았다")
    assert_equal 1, scene.scan(/"pagoda__fresh"/).size, "주사의 자리가 여럿이다"
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

  test "문에는 이름을 붙이지 않는다 — 형상으로만" do
    # 「문」이라는 낱말은 괜찮다. 이름이 안 된다 — 일주문, 천왕문 같은.
    names = CopyLocks.pattern(:gate_names)
    sign_in_as users(:one)

    I18n.available_locales.each do |locale|
      [ threshold_path(locale: locale), threshold_naming_path(locale: locale), threshold_breath_path(locale: locale) ].each do |door|
        get door

        assert_no_match names, Nokogiri::HTML(response.body).css("body").text, "#{door} 에 문의 이름이 있다"
      end
    end
  end

  # 훗날 두 신장이 설 자리. 지금은 만들지 않는다.
  test "둘째 문의 양쪽 자리는 비어 있다" do
    sign_in_as users(:one)
    get threshold_naming_path

    assert_select ".threshold__flank", count: 2
    css_select(".threshold__flank").each do |flank|
      assert_equal "true", flank["aria-hidden"]
      assert_empty flank.children.reject { |child| child.text? && child.text.strip.empty? }, "빈 자리에 무언가 서 있다"
    end
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
