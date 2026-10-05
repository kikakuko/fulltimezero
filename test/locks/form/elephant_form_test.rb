# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 결 — 흰빛이 어떻게 오르내리는지, 정거장이 몇인지. 「아홉 자리와 잇지 않는다」와
# 「리셋이 없다」는 약속 쪽이다 — test/locks/promise/elephant_promise_test.rb.
require "test_helper"

class ElephantFormTest < ActiveSupport::TestCase
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

  test "창은 오늘을 포함한 스물여드레다" do
    @user.rests.create!(rested_on: @today - 27, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9

    @user.rests.create!(rested_on: @today - 28, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9, "스물아흐레 전이 창에 들어온다"
  end

  test "어제의 값을 함께 준다" do
    @user.rests.create!(rested_on: @today, duration: "a_while")
    reading = Elephant.for(@user)

    assert_in_delta 1 / 28.0, reading.whiteness, 1e-9
    assert_equal 0.0, reading.yesterday
    assert reading.moved?
  end

  test "정거장은 아홉이고 지명일 뿐이다" do
    assert_equal 0, Elephant::Reading.new(whiteness: 0.0, yesterday: 0.0).station
    assert_equal 8, Elephant::Reading.new(whiteness: 1.0, yesterday: 1.0).station
    assert_equal 4, Elephant::Reading.new(whiteness: 0.5, yesterday: 0.5).station
  end
end
