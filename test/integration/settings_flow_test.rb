# This app is a raft. — 이 앱도 뗏목이다.
#
# 설정 — 부품으로 옮긴 뒤에도 언어를 바꾸고, 매일의 문을 끄고, 전부 받아 갈 수 있다(§7).
require "test_helper"

class SettingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "설정은 부품 다섯으로 선다 — 먹 알약 하나, 조용한 버튼 둘, 옛 버튼 없이" do
    get settings_path

    assert_select ".button-primary", count: 1
    assert_select "form button[type=submit].button-primary", text: I18n.t("settings.save")
    assert_select "button.button-quiet", count: 2
    assert_select "input[type=submit]", false, "옛 제출 칸이 남아 있다"
  end

  test "앱을 여는 문의 이름은 「매일의 문」이다" do
    get settings_path(locale: :ko)
    assert_select "label", text: "매일의 문"
    assert_no_match(/숨 한 번|앱을 열 때/, response.body)
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
