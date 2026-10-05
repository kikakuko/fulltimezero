# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 흰빛이 도는가 — 무엇이든 있었던 날이 세어지고, 하루에 여럿이어도 하루다.
require "test_helper"

class ElephantTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.rests.destroy_all
    @user.sittings.destroy_all
    @user.clearings.destroy_all
    @user.copyings.destroy_all
    @today = @user.today
  end


  test "아무것도 없으면 검다" do
    assert_equal 0.0, Elephant.for(@user).whiteness
  end

  test "쉼 · 앉음 · 비움 · 사경 — 무엇이든 있었던 날이 흰빛이 된다" do
    @user.rests.create!(rested_on: @today, duration: "a_while")
    @user.sittings.create!(sat_on: @today - 1, mode: "nothing", ended_at: Time.current)
    @user.clearings.create!(cleared_on: @today - 2)
    @user.copyings.create!(sutra_char: heart_sutra.chars.first, copied_on: @today - 3, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    assert_in_delta 4 / 28.0, Elephant.for(@user).whiteness, 1e-9
  end

  test "하루에 여럿이어도 하루다" do
    @user.rests.create!(rested_on: @today, duration: "a_while")
    @user.rests.create!(rested_on: @today, duration: "a_moment")
    @user.sittings.create!(sat_on: @today, mode: "sitting", ended_at: Time.current)

    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9
  end

  test "어제의 값을 함께 준다" do
    @user.rests.create!(rested_on: @today, duration: "a_while")
    reading = Elephant.for(@user)

    assert_in_delta 1 / 28.0, reading.whiteness, 1e-9
    assert_equal 0.0, reading.yesterday
    assert reading.moved?
  end
end
