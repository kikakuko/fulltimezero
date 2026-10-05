# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 결 — 창은 스물여드레, 정거장은 아홉.
require "test_helper"

class ElephantWhiteTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.rests.destroy_all
    @user.sittings.destroy_all
    @user.clearings.destroy_all
    @user.copyings.destroy_all
    @today = @user.today
  end


  test "창은 오늘을 포함한 스물여드레다" do
    @user.rests.create!(rested_on: @today - 27, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9

    @user.rests.create!(rested_on: @today - 28, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9, "스물아흐레 전이 창에 들어온다"
  end

  test "정거장은 아홉이고 지명일 뿐이다" do
    assert_equal 0, Elephant::Reading.new(whiteness: 0.0, yesterday: 0.0).station
    assert_equal 8, Elephant::Reading.new(whiteness: 1.0, yesterday: 1.0).station
    assert_equal 4, Elephant::Reading.new(whiteness: 0.5, yesterday: 0.5).station
  end
end
