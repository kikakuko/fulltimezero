# This app is a raft. — 이 앱도 뗏목이다.
#
# 매일 지나는 문 — 앱을 열 때마다 숨 한 번 쉬는 어둠.
require "test_helper"

class DailyDoorTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "앱을 열면 숨 한 번의 어둠이 지나가고, 화면을 옮기는 사이에는 다시 오지 않는다" do
    get today_path
    assert_select ".daily-door[data-controller=daily-door]"

    get days_path
    assert_select ".daily-door", false
  end

  test "한동안 오지 않다가 돌아오면 다시 지나간다" do
    get today_path

    travel(ApplicationController::DAILY_DOOR_AFTER + 1.minute) do
      get today_path
      assert_select ".daily-door"
    end
  end

  test "누르면 곧장 걷힌다" do
    get today_path

    assert_select ".daily-door[data-action*='click->daily-door#pass']"
  end

  test "설정에서 끌 수 있다" do
    patch settings_path, params: { user: { daily_door: "0" } }
    refute @user.reload.daily_door

    travel(ApplicationController::DAILY_DOOR_AFTER + 1.minute) do
      get today_path
      assert_select ".daily-door", false
    end
  end

  test "처음의 문 셋 위에는 매일의 문이 겹치지 않는다" do
    @user.update!(onboarded_at: nil)
    get threshold_path

    assert_select ".daily-door", false
  end

  test "들어오기 전에는 없다" do
    sign_out
    get gate_path
    follow_redirect!

    assert_select ".daily-door", false
  end
end
