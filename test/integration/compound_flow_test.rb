# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내가 도는가 — 전각 여섯 모두에 가는 길이 있고, 그 길이 열린다. 길이 막히면 앱이
# 고장난 것이다. 그 길이 카드로 열리는지(나중에 전체화면이 될 수도 있다)는 결 쪽이다 —
# test/locks/form/compound_flow_test.rb.
require "test_helper"

class CompoundFlowTest < ActionDispatch::IntegrationTest
  setup do
    heart_sutra
    @user = users(:one)
    sign_in_as @user
  end

  # 마당은 같은 화면 아래로 내려가는 자리라 주소가 아니라 닻이다.
  WAYS = { sitting: :new_sitting_path, maitreya: :days_path, copying: :new_copying_path,
           lecture: :guide_path, gate: :threshold_path }.freeze

  test "전각 여섯 모두에 가는 길이 있고, 그 길이 열린다" do
    get today_path

    WAYS.each do |key, way|
      assert_select "a.compound__hall--#{key}[href=?]", public_send(way), count: 1,
        message: "#{key} 으로 가는 길이 마당에 없다"
    end
    assert_select "a.compound__hall--courtyard[href=?]", "#clearing", count: 1
    assert_select "#clearing", count: 1, message: "마당을 누르면 내려갈 자리가 없다"

    WAYS.each_value do |way|
      get public_send(way)
      assert_response :success, "#{way} 가 열리지 않는다"
    end
  end

  test "전각의 이름을 눌러 그 방으로 들어간다" do
    get new_sitting_path
    assert_response :success
    assert_select ".hall-header__name", text: I18n.t("compound.halls.sitting")

    get new_copying_path
    assert_response :success
    assert_select ".hall-header__name", text: I18n.t("compound.halls.copying")
  end
end
