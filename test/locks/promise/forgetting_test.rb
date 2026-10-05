# This app is a raft. — 이 앱도 뗏목이다.
#
# 쉼 기록은 사용자의 것이다(SPIRIT §4). 계정을 통째로 지우지 않고도
# 한 줄씩 지울 수 있어야 한다.
require "test_helper"

class ForgettingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @rest = @user.rests.create!(rested_on: @user.today, duration: "a_while", texture: "walked")
    @sitting = @user.sittings.create!(mode: "nothing")
  end

  test "그 날의 쉼과 앉음이 하루 화면에 보이고, 지우기 전에 한 번 묻는다" do
    get day_path(@user.today)

    assert_select "form[action=?][data-turbo-confirm]", rest_path(@rest)
    assert_select "form[action=?][data-turbo-confirm]", sitting_path(@sitting)
    assert_match I18n.t("rests.durations.a_while"), response.body
  end

  test "쉼 기록을 한 줄 지운다" do
    assert_difference -> { @user.rests.count }, -1 do
      delete rest_path(@rest)
    end

    assert_redirected_to day_path(@user.today)
  end

  test "앉음을 하나 지운다" do
    assert_difference -> { @user.sittings.count }, -1 do
      delete sitting_path(@sitting)
    end

    assert_redirected_to day_path(@user.today)
  end

  test "지우면 달도 그만큼 덜 찬다 — 그뿐이다" do
    assert @user.moon.days.last.rested?

    delete rest_path(@rest)
    delete sitting_path(@sitting)

    refute @user.reload.moon.days.last.rested?
  end

  test "남의 기록은 지울 수 없다" do
    other = users(:two)
    theirs = other.rests.create!(rested_on: other.today, duration: "one_breath")

    assert_no_difference -> { Rest.count } do
      delete rest_path(theirs)
    end

    assert_response :not_found
  end

  test "지운다고 알림이 가지 않는다" do
    assert_no_enqueued_emails { delete rest_path(@rest) }
  end
end
