# This app is a raft. — 이 앱도 뗏목이다.
#
# 한 번의 사건은 한 번만 온다. 달의 응답 · 낙관의 찍힘은 flash 로 넘기므로 그 화면을 처음
# 받는 요청이 가져간다. Turbo 의 미리 받기(손을 올리면 미리 GET)가 그 요청을 먼저 하면
# 사람이 보는 화면에는 사건이 없다 — 그래서 앱 전체에서 미리 받기를 끈다. 그리고 두 번째
# 요청에서는 사건이 되풀이되지 않는다.
require "test_helper"

class FlashOnceTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.rests.destroy_all
    @user.sittings.destroy_all
    sign_in_as @user
  end

  test "미리 받기는 앱 전체에서 꺼져 있다" do
    get today_path
    assert_select "head meta[name=turbo-prefetch][content=false]", count: 1
  end

  test "미리 받기가 있어도 달은 한 번 응답한다 — 처음 받는 화면에만, 되풀이되지 않는다" do
    post rests_path
    assert_redirected_to today_path

    # 처음 받는 화면 — 사건이 실려 있다. 미리 받기가 있었다면 이 요청이 그것이고, 그래서 끈다.
    follow_redirect!
    assert_select "svg.moon--filling", count: 1, message: "첫 틈에 달이 응답하지 않는다"

    # 같은 화면을 다시 받으면 사건은 없다 — 달은 이미 그 자리다.
    get today_path
    assert_select "svg.moon--filling", false, "달의 응답이 되풀이된다"
    assert_select "form#rest.rest--stamped", false, "낙관이 다시 찍힌다"
  end
end
