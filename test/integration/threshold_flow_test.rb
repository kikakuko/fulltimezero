# This app is a raft. — 이 앱도 뗏목이다.
#
# 문 셋이 도는가 — 계정 없이 지나고, 적은 한 줄이 남고, 지난 뒤에는 마당으로 간다. 깨지면 버그다.
# 문이 어떻게 생겼는가는 자물쇠 쪽이다 — test/locks/form/threshold_test.rb.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class ThresholdFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(onboarded_at: nil)
    sign_in_as @user
  end


  test "문 앞의 사람은 오늘에 앞서 첫째 문으로 간다" do
    get today_path

    assert_redirected_to threshold_path
  end

  test "적은 한 줄은 받아 두기만 한다" do
    patch threshold_naming_path, params: { user: { what_moves: "  끝나지 않는 생각  " } }

    assert_equal "끝나지 않는 생각", @user.reload.what_moves
    assert_redirected_to threshold_breath_path
  end

  test "비워 두고 지나갈 수 있다" do
    patch threshold_naming_path, params: { user: { what_moves: "" } }

    assert_nil @user.reload.what_moves
    assert_redirected_to threshold_breath_path
  end

  test "문이 열리면 오늘 화면으로 가고, 다시 붙잡지 않는다" do
    post threshold_passed_path

    assert @user.reload.onboarded?
    assert_redirected_to today_path
    get today_path
    assert_response :success
  end

  test "어느 문에서든 「나중에」로 지나갈 수 있다" do
    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door
      assert_select "form[action=?] button", threshold_passed_path, text: I18n.t("threshold.later")
    end
  end

  test "문을 다시 지나도 처음 지난 날은 바뀌지 않는다" do
    post threshold_passed_path
    first = @user.reload.onboarded_at

    travel 3.days { post threshold_passed_path }

    assert_equal first.to_i, @user.reload.onboarded_at.to_i
  end

  # 문은 가입보다 먼저다. 처음 온 사람은 계정 없이 문 셋을 지나고, 셋째 문
  # 뒤에 가입한다. 둘째 문의 답은 세션이 들고 있다가 계정으로 옮긴다.
  test "처음 온 사람은 앱을 열면 바로 첫째 문 앞에 선다" do
    sign_out
    get gate_path

    assert_redirected_to threshold_path
    follow_redirect!
    assert_select ".gates__line", text: I18n.t("threshold.stop.line")
    assert_select "nav.doors", false
  end

  test "들어온 사람은 앱을 열면 마당으로 간다" do
    @user.update!(onboarded_at: Time.current)
    get gate_path

    assert_redirected_to today_path
  end

  test "계정 없이 문 셋을 지나고, 셋째 문 뒤에 가입한다" do
    sign_out

    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door
      assert_response :success, "#{door} 가 계정 없이 열리지 않는다"
    end

    patch threshold_naming_path, params: { user: { what_moves: "  끝나지 않는 생각  " } }
    assert_redirected_to threshold_breath_path

    post threshold_passed_path
    assert_redirected_to new_user_path
    follow_redirect!
    assert_match I18n.t("gate.line"), Nokogiri::HTML(response.body).css("main").text, "가입 화면에 그 한 줄이 없다"

    post users_path, params: { user: { email_address: "walked@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    user = User.find_by!(email_address: "walked@fulltimezero.test")

    assert user.onboarded?, "문을 지났는데 가입 뒤에 다시 문 앞이다"
    assert_equal "끝나지 않는 생각", user.what_moves, "둘째 문의 답이 계정에 옮겨지지 않았다"
    assert_redirected_to today_path
    follow_redirect!
    assert_response :success
  end

  test "가입 없이 나가면 둘째 문의 답은 버려진다" do
    sign_out
    patch threshold_naming_path, params: { user: { what_moves: "잊힐 한 줄" } }

    assert_empty User.where(what_moves: "잊힐 한 줄")
    reset!

    post users_path, params: { user: { email_address: "fresh@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    fresh = User.find_by!(email_address: "fresh@fulltimezero.test")
    assert_nil fresh.what_moves
    refute fresh.onboarded?, "문을 지나지 않았는데 지난 것으로 되어 있다"
  end

  test "문을 지나지 않고 가입한 사람은 마당에 앞서 문으로 간다" do
    sign_out
    post users_path, params: { user: { email_address: "direct@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    follow_redirect!

    assert_redirected_to threshold_path
  end
end
