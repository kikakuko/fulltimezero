# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경 — 하루 한 자. 채점도 인식도 없다. 쓰면 그걸로 한 자다.
require "test_helper"

class CopyingFlowTest < ActionDispatch::IntegrationTest
  STROKES = [ [ [ 0.2, 0.3 ], [ 0.5, 0.35 ], [ 0.8, 0.4 ] ], [ [ 0.5, 0.1 ], [ 0.5, 0.9 ] ] ].freeze

  setup do
    @user = users(:one)
    @sutra = heart_sutra
    sign_in_as @user
  end

  test "오늘의 한 자와 그 곁의 글이 보인다" do
    char = @sutra.chars.first
    get new_copying_path

    assert_select ".copy-model", text: char.glyph
    assert_match char.reading, response.body
    assert_match char.sense_here, response.body
    assert_match char.gloss_en, response.body
  end

  test "구절에서 지금 쓰는 자만 진하다" do
    already_wrote_through(5) # 다음은 여섯째 자 — 行
    char = @sutra.chars.find_by!(pos: 6)
    get new_copying_path

    assert_select ".copy-phrase strong", count: 1, text: char.glyph
    assert_select ".copy-phrase", text: char.phrase.han
  end

  test "소리를 옮긴 자에는 뜻 대신 산스크리트 원어가 선다" do
    already_wrote_through(3) # 다음은 넷째 자 — 菩
    char = @sutra.chars.find_by!(pos: 4)
    assert char.transliterated?

    get new_copying_path

    assert_match char.sanskrit["word"], response.body
    assert_match char.sanskrit["syllable"], response.body
    assert_no_match char.sense_here, response.body
  end

  # 몇 번째인지, 모두 몇 번인지는 세지 않는다. 다시 온다는 것만 말한다.
  test "다시 오는 자는 다음에 만날 구절만 말한다" do
    already_wrote_through(3)
    char = @sutra.chars.find_by!(pos: 4)
    again = @sutra.chars.where(glyph: char.glyph).where("pos > ?", char.pos).order(:pos).first.phrase

    get new_copying_path

    assert_match I18n.t("copyings.again", phrase: again.han), response.body
    assert_no_match(/\d/, Nokogiri::HTML(response.body).css("main").text, "사경 화면에 숫자가 보인다")
  end

  test "이 경에서 다시 오지 않는 자에는 그 말이 없다" do
    char = @sutra.chars.first
    assert_equal 1, @sutra.chars.where(glyph: char.glyph).count

    get new_copying_path

    assert_no_match I18n.t("copyings.again", phrase: "").split("「").first, response.body
  end

  test "올리면 그어진 획 그대로 한 자가 된다" do
    assert_difference -> { @user.copyings.count }, 1 do
      post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }
    end

    assert_equal STROKES, @user.copyings.last.glyph_paths
    follow_redirect!
    assert_match I18n.t("today.done"), response.body
  end

  test "올리면 방금 쓴 글씨가 앉을 탑을 함께 돌려준다" do
    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }, as: :json

    assert_response :created
    scene = response.parsed_body["scene"]
    fresh = scene["cells"].find { |cell| cell["fresh"] }

    assert_equal 1, fresh["pos"]
    assert_equal STROKES, fresh["paths"]
    assert_equal 1, scene["cells"].size, "쓰지 않은 칸의 자리가 함께 나갔다"
  end

  test "이미 쓴 날에는 장면 없이 되돌려 보낸다" do
    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }, as: :json
    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }, as: :json

    assert_response :unprocessable_entity
  end

  # 탑은 잠깐 보였다 사라져야 한다. 머물면 자기 탑을 세게 된다.
  test "오늘 몫이 끝난 화면에는 탑이 머물지 않는다" do
    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }
    get new_copying_path

    assert_match I18n.t("today.done"), response.body

    # 머리말의 모듈 목록이 아니라, 사용자가 보는 본문에 탑이 있는지를 본다.
    main = Nokogiri::HTML(response.body).at_css("main")
    assert_empty main.css("[class*=pagoda], [data-copying-pagoda-value]"), "몫이 끝난 뒤에도 탑이 화면에 남는다"
  end

  # 아홉 달을 쌓는 것을 하루 한 번 잠깐만 보게 하는 것은 가혹하다.
  # 탑은 언제든 볼 수 있다 — 세는 것을 막는 일은 탑 화면이 한다.
  test "사경에서 탑으로 가는 길이 늘 있다" do
    get new_copying_path
    assert_select "a[href=?]", pagoda_path, count: 1

    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }
    get new_copying_path

    assert_match I18n.t("today.done"), response.body
    assert_select "a[href=?]", pagoda_path, count: 1, message: "오늘 몫이 끝나면 탑으로 가는 길이 사라진다"
  end

  # 탑의 그림은 손으로 그린 것이다. 좌표도 곡선도 코드가 만들지 않는다.
  test "탑은 그려 둔 윤곽을 그대로 심는다" do
    get new_copying_path

    assert_select "template[data-copying-target=art] svg.pagoda__art", count: 1
    assert_select "template[data-copying-target=art] .bell[data-layer]", count: 10, message: "층마다 풍경 둘"

    layout = Rails.root.join("app/models/pagoda_layout.rb").read
    assert_no_match(/"M |eave_path|outline_path/, layout, "탑의 선을 코드가 그린다")

    # 안 찬 층은 처마만 남는다. 풍경이 미리 걸려 있으면 몇 층이 남았는지가 세어진다.
    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read
    assert_match(/if \(!floors\.filled\.includes\(layer\)\) return bell\.remove\(\)/, scene,
      "차지 않은 층에도 풍경이 걸린다")
  end

  # 글씨가 주인공이고 탑은 자리다. 옅기는 손으로 고칠 수 있게 상수로 둔다.
  test "윤곽은 옅게 깔린다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    art = css[/\.pagoda__art \{.*?\n\}/m]

    assert_match(/--art: 0\.3;/, art.to_s)
    assert_match(/--art-pillar: [\d.]+;/, art.to_s, "기둥선을 따로 옅게 할 수 없다")
    assert_match(/--art-bell: [\d.]+;/, art.to_s, "풍경의 진하기를 따로 정할 수 없다")
    assert_match(/\.pagoda__eave \{[^}]*opacity: var\(--art\)/, css)
    assert_match(/\.pagoda__pillar \{[^}]*opacity: calc\(var\(--art\) \* var\(--art-pillar\)\)/, css)
  end

  # 탑은 통째로 보여야 탑이다. 앉는 동안만 다가가고, 끝에는 물러난다.
  test "다가갔다 물러나 탑 전체를 보인다 — 잘라 보이지 않는다" do
    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/camera\.setAttribute\("transform", "translate\(0 0\) scale\(1\)"\)/, scene,
      "물러나 탑 전체가 되지 않는다")
    assert_match(/\.pagoda__camera--widening \{ transition: transform \d+ms /, css)
    assert_match(/\.pagoda \{ height: min\(84vh, 48rem\); width: auto; max-width: 92vw; \}/, css,
      "탑이 화면에 다 들어오지 않는다")
  end

  # 날아가는 결. 밋밋하지 않게 넷을 얹되, 길이는 그대로 팔 할 초다.
  test "글씨는 호를 그리며 날아가 지나쳤다 되돌아와 앉는다" do
    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read

    assert_match(/const FLIGHT = 800\b/, scene, "나는 동안이 팔 할 초가 아니다")
    assert_match(/const x = dx \* t$/, scene, "가로가 고르게 가지 않는다")
    assert_match(/Math\.sin\(Math\.PI \* t\)/, scene, "솟았다 내려앉는 호가 없다")
    assert_match(/const OVERSHOOT = 2\b/, scene, "지나쳤다 되돌아오지 않는다")
    assert_match(/easing = "ease-out"/, scene, "되돌아오는 끝이 느려지지 않는다")
  end

  test "앉는 순간과 층이 차는 순간에만 한 번씩 움직인다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    settle = css[/@keyframes ink-settle \{[^\n]*\}/]
    assert_match(/\.pagoda__settling \{ animation: ink-settle 0\.15s /, css, "앉는 순간이 찰나가 아니다")
    assert_match(/scale\(0\.92\)/, settle.to_s, "먹이 번지는 움츠림이 없다")

    sway = css[/@keyframes bell-sway \{.*?\n\}/m]
    assert_match(/\.bell--stirred \{ animation: bell-sway 1\.2s /, css)

    # 매다는 자리는 그림에서 읽는다 — 손으로 적어 두면 윤곽을 다시 그릴 때 어긋난다.
    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read
    assert_match(/hangingPoint\(bell\)/, scene)
    assert_match(/bell\.querySelector\("path"\)\?\.getAttribute\("d"\)/, scene)
    assert_no_match(/\.bell--stirred \{[^}]*transform-origin/, css, "매다는 자리를 손으로 적었다")
    degrees = sway.to_s.scan(/rotate\((-?[\d.]+)deg\)/).flatten.map { |turn| turn.to_f.abs }
    assert_equal 3.0, degrees.max, "풍경이 삼 도 넘게 흔들린다"
    assert_operator degrees.each_cons(2).count { |before, after| after > before }, :<=, 1,
      "흔들림이 점점 작아지지 않는다"
  end

  # 움직임을 줄인 화면에서는 넷 다 끄고 그냥 앉는다.
  test "움직임을 줄이면 날지도 움츠리지도 흔들리지도 않는다" do
    scene = Rails.root.join("app/javascript/lib/pagoda_scene.js").read

    assert_match(/if \(fresh && flier && !reduced\) await fly/, scene)
    assert_match(/glyph\(fresh, \{ settling: !reduced \}\)/, scene)
    assert_match(/buildPagoda\(\{ scene, art, label, stirred: !reduced \}\)/, scene)
    assert_match(/const near = fresh && !reduced && nearView/, scene, "움직임을 줄여도 틀이 움직인다")
  end

  test "앉는 순간 떨지 말지는 게이트가 정한다" do
    get new_copying_path
    assert_select "[data-copying-vibrate-value=true]"

    stubbing(SilenceGate, :allow?, false) { get new_copying_path }
    assert_select "[data-copying-vibrate-value=false]"
  end

  # 「종이에 썼다」는 확인할 수 없는 선언이라 누르기만 하면 탑이 서고,
  # 그 탑은 자기 글씨가 아니라 활자뿐이게 된다. 걷어냈다.
  test "쓰는 자리에는 「다시 쓴다」와 「올린다」 둘뿐이다" do
    get new_copying_path

    assert_select ".copy-offer button, .copy-offer input[type=submit]", count: 2
    assert_no_match(/on_paper/, response.body)
  end

  test "쓰지 않았다는 선언으로는 한 자가 되지 않는다" do
    assert_no_difference -> { @user.copyings.count } do
      post copyings_path, params: { on_paper: 1 }
    end
  end

  test "하루 한 자를 이미 썼으면 오늘 몫은 끝났다" do
    post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }

    get new_copying_path
    assert_match I18n.t("today.done"), response.body
    assert_select "svg[data-copying-target=surface]", false, "몫이 끝났는데 쓰는 자리가 열려 있다"

    assert_no_difference -> { @user.copyings.count } do
      post copyings_path, params: { copying: { glyph_paths: STROKES.to_json } }
    end
  end

  test "한 획도 긋지 않고는 올릴 수 없다" do
    get new_copying_path
    assert_select "input[type=submit][disabled][data-copying-target=offer]"

    assert_no_difference -> { @user.copyings.count } do
      post copyings_path, params: { copying: { glyph_paths: "[]" } }
    end
  end

  test "알아볼 수 없는 획은 받지 않는다" do
    assert_no_difference -> { @user.copyings.count } do
      post copyings_path, params: { copying: { glyph_paths: "획이 아니다" } }
    end

    follow_redirect!
    assert_select ".flash"
  end

  test "경을 끝까지 쓰면 그렇게만 말한다" do
    already_wrote_through(@sutra.total)
    get new_copying_path

    assert_match I18n.t("copyings.finished"), response.body
  end

  # 채점도, 인식도, 정확도도 없다(제3조). 주석은 왜 하지 않는지를 적은 자리라 걷어낸다.
  test "사경에 채점하는 코드가 없다" do
    grading = /score|accura|correct|grade|recogni|similar|match_glyph|점수|채점|정확도|맞았|틀렸/i
    files = %w[app/javascript/controllers/copying_controller.js app/controllers/copyings_controller.rb
               app/models/copying.rb app/views/copyings/new.html.erb]

    offenders = files.select do |file|
      Rails.root.join(file).read.gsub(%r{^\s*(//|#).*$}, "").gsub(/<%#.*?%>/m, "").match?(grading)
    end

    assert_empty offenders, "사경이 글씨를 채점한다"
  end

  test "붓은 우리 서버에서만 온다 — 바깥을 부르지 않는다" do
    get new_copying_path

    assert_match %r{/assets/perfect-freehand-[0-9a-f]+\.js}, response.body
    assert_no_match(/jspm|jsdelivr|unpkg|esm\.sh/, response.body)
  end

  private
    # 지난날들에 이미 써 온 것처럼 탑을 쌓아 둔다.
    def already_wrote_through(pos)
      today = @user.today
      rows = @sutra.chars.where(pos: 1..pos).map do |char|
        { user_id: @user.id, sutra_char_id: char.id, copied_on: today - (pos - char.pos + 1),
          glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
      end
      Copying.insert_all!(rows)
    end
end
