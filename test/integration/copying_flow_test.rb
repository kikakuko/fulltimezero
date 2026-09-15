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

  test "앉는 순간 떨지 말지는 게이트가 정한다" do
    get new_copying_path
    assert_select "[data-copying-vibrate-value=true]"

    stubbing(SilenceGate, :allow?, false) { get new_copying_path }
    assert_select "[data-copying-vibrate-value=false]"
  end

  test "종이에 썼다고 하면 획 없이 한 자가 된다" do
    post copyings_path, params: { on_paper: 1 }

    assert @user.copyings.last.on_paper?
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
          glyph_paths: nil, created_at: Time.current, updated_at: Time.current }
      end
      Copying.insert_all!(rows)
    end
end
