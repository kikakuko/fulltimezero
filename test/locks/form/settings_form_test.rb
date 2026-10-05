# This app is a raft. — 이 앱도 뗏목이다.
#
# 설정의 결 — 부품 다섯과 「매일의 문」이라는 이름.
require "test_helper"

class SettingsFormTest < ActionDispatch::IntegrationTest
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
end
