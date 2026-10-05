# This app is a raft. — 이 앱도 뗏목이다.
#
# 설정이 도는가 — 언어를 바꾸고, 매일의 문을 끄고, 전부 받아 간다. 깨지면 버그다.
require "test_helper"

class SettingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end


  test "먹 알약으로 언어를 바꾸고 매일의 문을 끈다" do
    patch settings_path, params: { user: { locale: "en", daily_door: "0" } }

    @user.reload
    assert_equal "en", @user.locale
    assert_not @user.daily_door
  end

  test "전체 반출은 그대로 받는다 — 마크다운과 JSON" do
    get settings_path
    assert_select "a[href=?]", export_path
    assert_select "a[href=?]", export_path(format: :json)

    get export_path
    assert_response :success
    get export_path(format: :json)
    assert_response :success
  end
end
