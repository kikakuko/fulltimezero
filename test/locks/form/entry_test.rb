# This app is a raft. — 이 앱도 뗏목이다.
#
# 전각에 드는 전환의 결(docs/M-entry-design.md, 2026-10-22). 「든다」를 누르면 조감도가 그 전각의
# 가운데를 축으로 커지며 사라지고, 그 방이 같은 시간에 겹쳐 들어온다. 나올 때는 거꾸로. 전환은
# Turbo 8 의 View Transition 이고, 움직임을 줄인 화면에서는 Turbo 가 스스로 끈다.
# 값(2.4 배 · 1.6초)은 결이라 바꿀 수 있다. 「축은 다음 방문에서 걷힌다」와 「전환 중 두 화면이
# 동시에 손을 받지 않는다」는 한 번 잘못되면 화면이 튀거나 엉뚱한 것이 눌리는 자리라 함께 잠근다.
require "test_helper"

class EntryTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  CONTROLLERS = Rails.root.join("app/javascript/controllers")
  COMPOUND = CONTROLLERS.join("compound_controller.js")
  ENTRY = CONTROLLERS.join("entry_controller.js")
  # 글 자리(hall-words)가 서는 전각 화면 — 전환의 한쪽이다. 불이문은 첫째 문으로 간다.
  HALL_PAGES = %i[new_sitting_path days_path new_copying_path guide_path bows_path bells_path].freeze

  setup do
    heart_sutra
    sign_in_as users(:one)
  end

  def css = CSS.read
  def root = css[/:root \{.*?\n\}/m]

  test "확대는 전각의 가운데를 축으로 2.4 배 · 1.6초, 두 화면이 같은 시간 같은 곡선으로 엇갈린다" do
    assert_match(/--entry-time: 1\.6s;/, root, "전환의 시간이 :root 에 없다")
    assert_match(/--entry-scale: 2\.4;/, root, "확대의 배율이 :root 에 없다")
    assert_match(/\.compound__scene \{[^}]*view-transition-name: compound;/, css, "조감도에 전환의 이름이 없다")
    assert_match(/\.hall-figure \{ view-transition-name: hall; \}/, css, "전각 그림에 전환의 이름이 없다")

    axis = /transform-origin: var\(--zoom-x, 50%\) var\(--zoom-y, 50%\);/
    assert_match(/::view-transition-old\(compound\) \{\s*#{axis}\s*animation: entry-away var\(--entry-time\) ease-in-out both;/m, css, "들어갈 때 조감도가 축에서 커지지 않는다")
    assert_match(/::view-transition-new\(compound\) \{\s*#{axis}\s*animation: entry-back var\(--entry-time\) ease-in-out both;/m, css, "나올 때 조감도가 축으로 돌아오지 않는다")
    assert_match(/::view-transition-old\(hall\) \{ animation: entry-fade-out var\(--entry-time\) ease-in-out both; \}/, css)
    assert_match(/::view-transition-new\(hall\) \{ animation: entry-fade-in var\(--entry-time\) ease-in-out both; \}/, css)
    assert_match(/@keyframes entry-away \{ from \{ transform: scale\(1\); opacity: 1; \} to \{ transform: scale\(var\(--entry-scale\)\); opacity: 0; \} \}/, css)
    assert_match(/@keyframes entry-back \{ from \{ transform: scale\(var\(--entry-scale\)\); opacity: 0; \} to \{ transform: scale\(1\); opacity: 1; \} \}/, css)
    # 지원하지 않는 브라우저의 확대도 같은 값, 같은 시간.
    assert_match(/\.compound--zooming \.compound__scene \{[^}]*transform: scale\(var\(--entry-scale\)\);\s*transition: transform var\(--entry-time\) ease-in-out;/m, css)
    entry = css[/── 전각에 드는 흐름.*?── 하루의 때/m]
    assert_no_match(/scale\(2\.\d\)|\d\.\ds\b/, entry, "확대 값이 :root 밖에 박혀 있다")
    # 가로로 넘친 것은 화면 밖이다 — 문서가 화면보다 넓어지면 뷰포트가 바뀐 것으로 보아 전환이 깨진다.
    assert_match(/\.sheet \{[^}]*overflow-x: clip;/, css, "본문 틀이 가로로 넘친 것을 자르지 않는다 — 구름과 걸어오는 코끼리가 문서를 넓혀 전환이 깨진다")
    # 움직임을 줄이면 Turbo 가 스스로 끈다 — 전환의 의사 요소에 따로 손대지 않는다.
    assert_no_match(/::view-transition[^{]*\{[^}]*animation: none/, css)
  end

  test "전환의 meta 는 마당과 전각 화면에만 있고, 문 셋과 몰입 화면에는 없다" do
    meta = "head meta[name=view-transition][content=same-origin]"

    get today_path
    assert_select meta, count: 1, message: "마당에 전환의 meta 가 없다"
    assert_select ".compound__scene", count: 1
    HALL_PAGES.each do |way|
      get send(way)
      assert_select meta, count: 1, message: "#{way} 에 전환의 meta 가 없다"
      assert_select ".hall-words[data-controller=entry][data-entry-x-value][data-entry-y-value]", count: 1
    end
    get new_sitting_path
    assert_select ".elephant-field.hall-figure", count: 1
    get days_path
    assert_select ".maitreya.hall-figure", count: 1

    get threshold_path
    assert_select meta, false, "첫째 문에 전환의 meta 가 있다 — 남겨 두는 요소(#gates)와 섞인다"
    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select meta, false, "앉는 중에 전환의 meta 가 있다"
    assert_select ".elephant-field.hall-figure", false, "앉는 중의 산수가 전환의 이름을 가진다"

    turbo = Gem.loaded_specs.fetch("turbo-rails").full_gem_path + "/app/assets/javascripts/turbo.min.js"
    assert_includes File.read(turbo), "startViewTransition", "Turbo 가 View Transition 을 모른다"
  end

  test "<html> 의 확대 축 값은 다음 방문에서 걷힌다" do
    compound = COMPOUND.read

    assert_match(/export function placeAxis\(cx, cy\) \{\s*const root = document\.documentElement\.style\s*root\.setProperty\("--zoom-x", `\$\{cx\}%`\)\s*root\.setProperty\("--zoom-y", `\$\{cy\}%`\)/m, compound)
    assert_match(/export function clearAxis\(\) \{[^}]*removeProperty\("--zoom-x"\)[^}]*removeProperty\("--zoom-y"\)/m, compound)

    # <html> 에 값을 넣는 손은 placeAxis 하나다.
    CONTROLLERS.glob("*.js").each do |file|
      next if file == COMPOUND

      assert_no_match(/documentElement\.style\.setProperty/, file.read, "#{file.basename} 이 <html> 에 제 손으로 값을 넣는다")
    end
    assert_equal 2, compound.scan(/documentElement\.style/).size, "<html> 에 손대는 자리가 placeAxis · clearAxis 둘이 아니다"

    # 축을 놓는 컨트롤러마다 다음 방문에서 걷는 손을 걸고, 떠날 때 뗀다.
    placers = CONTROLLERS.glob("*_controller.js").select { |file| file.read.include?("placeAxis(") }
    assert_equal %w[compound entry], placers.map { |file| file.basename("_controller.js").to_s }.sort
    placers.each do |file|
      js = file.read
      assert_match(/addEventListener\("turbo:visit", clearAxis\)/, js, "#{file.basename} 이 다음 방문에서 축을 걷지 않는다")
      assert_match(/removeEventListener\("turbo:visit", clearAxis\)/, js, "#{file.basename} 이 떠날 때 손을 떼지 않는다")
      # 축은 옛 화면의 스냅숏이 담긴 뒤, 새 화면이 그려지기 전에 놓는다.
      assert_match(/addEventListener\("turbo:before-render"/, js, "#{file.basename} 이 축을 before-render 에서 놓지 않는다")
      assert_match(/removeEventListener\("turbo:before-render"/, js, "#{file.basename} 이 before-render 의 손을 떼지 않는다")
    end
  end

  test "전환 중 두 화면이 동시에 입력을 받지 않는다" do
    compound = COMPOUND.read

    # 전환이 도는 동안 ::view-transition 이 화면을 덮어 손을 받는다. pointer-events: none 을
    # 주면 그 밑의 산 화면이 손을 받는다 — 주지 않는다.
    assert_no_match(/::view-transition[^{]*\{[^}]*pointer-events/, css, "전환의 의사 요소가 손을 흘려보낸다")
    # 지원하지 않는 브라우저의 확대 동안 조감도는 손을 받지 않는다.
    assert_match(/\.compound--zooming \{ pointer-events: none; \}/, css)
    # 「든다」는 한 번만 든다. 카드를 닫은 뒤에 든다.
    assert_match(/if \(!this\.opened \|\| this\.entering\) return/, compound)
    assert_match(/this\.entering = true/, compound)
    assert_match(/this\.close\(\)\s*\n\s*if \(document\.startViewTransition\)/, compound, "카드가 열린 채로 든다")
  end

  # 그림은 첫 화면까지 — 높이만. 먹틀과 양옆 16px 은 그대로이고, 글과 손잡이는 한 화면 아래다.
  test "선방 · 미륵당의 그림은 첫 화면까지이고, 먹틀은 그대로이며, 글과 손잡이는 그림 아래다" do
    assert_match(/--hall-above: [\d.]+rem;/, root, "그림 위에 서는 것의 높이가 :root 에 없다")
    assert_match(/--hall-height: calc\(100svh - var\(--hall-above\)\);/, root, "그림의 높이가 첫 화면이 아니다")
    assert_match(/\.elephant-field\.hall-figure \{ aspect-ratio: auto; height: var\(--hall-height\); overflow: hidden; \}/, css)
    assert_match(/\.maitreya\.hall-figure \{ aspect-ratio: auto; height: var\(--hall-height\); \}/, css)
    # 무대는 그림의 비율로 틀 가운데에 — 자리 값은 바뀌지 않는다.
    assert_match(%r{\.hall-figure \.elephant-field__stage \{\s*inset: auto; left: 50%; top: 50%; translate: -50% -50%;\s*width: max\(100%, calc\(var\(--hall-height\) \* 864 / 1184\)\); aspect-ratio: 864 / 1184;}m, css)
    assert_match(%r{\.hall-figure \.maitreya__stage \{\s*inset: auto; left: 50%; top: 50%; translate: -50% -50%;\s*width: max\(100%, calc\(var\(--hall-height\) \* 390 / 560\)\); aspect-ratio: 390 / 560;}m, css)
    assert_match(/\.maitreya__stage \{ position: absolute; inset: 0; container-type: inline-size; \}/, css, "한 단위(--m-u)의 그릇이 무대가 아니다")
    # 먹틀과 양옆 16px 은 그대로(compound_form_test 의 규칙과 같다).
    %w[elephant-field maitreya].each do |frame|
      assert_match(/\.#{frame} \{[^}]*width: calc\(100% \+ 1rem\);[^}]*margin: 0 -0\.5rem/m, css, "#{frame} 먹틀에 가장자리가 없다")
    end

    { new_sitting_path => [ ".elephant-field.hall-figure.ink-frame", ".ways" ], days_path => [ ".maitreya.hall-figure.ink-frame", ".calendar" ] }.each do |path, (figure, handles)|
      get path
      assert_select figure, count: 1
      assert_select "#{figure} > :first-child[class$=__stage]", count: 1, message: "#{path} 의 그림에 무대가 없다"
      main = Nokogiri::HTML(response.body).css("main").to_html
      assert_operator main.index("hall-header"), :<, main.index("hall-figure"), "#{path} 에서 이름이 그림 위에 있지 않다"
      assert_operator main.index("hall-figure"), :<, main.index("hall-words"), "#{path} 에서 글이 그림 아래에 있지 않다"
      assert_operator main.index("hall-words"), :<, main.index(handles.delete(".")), "#{path} 에서 손잡이가 글 아래에 있지 않다"
    end
  end

  test "카드에는 이름 · 한 줄 · 「든다」만 있고, 전각 그림 한 장은 카드를 열 때 받는다" do
    get today_path

    assert_select ".compound__card > p", count: 2
    assert_select ".compound__card-name", count: 1
    assert_select ".compound__card-line", count: 1
    assert_select ".compound__card button.button-primary", count: 1
    %w[han verse source].each { |part| assert_select ".compound__card-#{part}", false, "카드에 #{part} 가 남아 있다" }

    # 전각 그림은 둘뿐이다. 주소만 실리고, 받는 것은 카드를 여는 손짓이다 — 첫 화면에 한 바이트도 더하지 않는다.
    assert_select "a.compound__hall--sitting[data-compound-picture-param*=elephant_field]", count: 1
    assert_select "a.compound__hall--maitreya[data-compound-picture-param*=mireukdang]", count: 1
    assert_select "a.compound__hall[data-compound-picture-param]", count: 2
    assert_select "main img[src*=elephant_field], main img[src*=mireukdang], link[rel=preload][as=image]", false, "마당이 전각 그림을 미리 받는다"
    assert_match(/if \(picture\) new Image\(\)\.src = picture/, COMPOUND.read)
  end
end
