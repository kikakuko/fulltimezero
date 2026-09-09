# This app is a raft. — 이 앱도 뗏목이다.
#
# 제7조. 강을 건넜으면 뗏목은 두고 간다 — 두고 가려면 들고 갈 것을
# 먼저 돌려받아야 한다. 내보내기는 선택 기능이 아니라 의무다.
require "test_helper"

class ExportFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.rests.create!(rested_on: @user.today, duration: "a_while", note: "창가에서")
    sign_in_as @user
  end

  test "설정 화면에서 두 가지 모양으로 받을 수 있다" do
    get settings_path

    assert_select "a[href=?]", export_path
    assert_select "a[href=?]", export_path(format: :json)
  end

  test "읽는 파일로 받는다" do
    get export_path

    assert_response :success
    assert_equal "text/markdown", response.media_type
    assert_match(/attachment; filename="fulltimezero-.*\.md"/, response.headers["Content-Disposition"])
    assert_includes response.body, "창가에서"
  end

  test "데이터 파일로 받는다" do
    get export_path(format: :json)

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_match(/attachment; filename="fulltimezero-.*\.json"/, response.headers["Content-Disposition"])
    assert_equal "창가에서", JSON.parse(response.body)["rests"].first["note"]
  end

  # 붙잡는 장치를 만들지 않는다. 확인도, 사유를 묻는 것도 없다.
  test "묻지 않고 한 번에 내준다" do
    get settings_path

    doors = Nokogiri::HTML(response.body).css("a[href*='export']")

    assert doors.any?, "내보내기로 가는 길이 없다"
    doors.each do |door|
      assert_nil door["data-turbo-confirm"], "내보내기가 사용자를 붙잡는다"
      assert_nil door["data-confirm"], "내보내기가 사용자를 붙잡는다"
    end
  end

  test "남의 기록은 받을 수 없다" do
    users(:two).rests.create!(rested_on: users(:two).today, duration: "one_breath", note: "남의 것")

    get export_path
    assert_not_includes response.body, "남의 것"
  end

  test "들어오지 않은 사람에게는 내주지 않는다" do
    sign_out
    get export_path

    assert_redirected_to new_session_path
  end

  test "내보내도 알림 한 통 나가지 않는다" do
    assert_no_enqueued_emails do
      get export_path
      get export_path(format: :json)
    end
  end

  test "내보내기는 바깥으로 나가지 않는다" do
    get export_path

    assert_no_match(%r{https?://}, response.body, "내보낸 파일이 바깥을 부른다")
  end
end
