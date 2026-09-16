# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 앉은 흔적. 아홉 자리와 잇지 않는다.
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

  test "창은 오늘을 포함한 스물여드레다" do
    @user.rests.create!(rested_on: @today - 27, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9

    @user.rests.create!(rested_on: @today - 28, duration: "a_while")
    assert_in_delta 1 / 28.0, Elephant.for(@user).whiteness, 1e-9, "스물아흐레 전이 창에 들어온다"
  end

  # 쉬지 않으면 서서히 내려갈 뿐이다. 0 으로 떨어지는 일은 없다 — 잊음이지 벌이 아니다.
  test "안 쉬면 서서히 내려갈 뿐, 리셋은 없다" do
    5.times { |i| @user.rests.create!(rested_on: @today - i, duration: "a_while") }
    now = Elephant.for(@user).whiteness

    later = (1..40).map { |days| Elephant.for(@user, today: @today + days).whiteness }

    assert_equal later.sort.reverse, later, "흰빛이 갑자기 오르거나 떨어진다"
    assert_operator later.first, :<=, now
    assert_operator later.each_cons(2).map { |a, b| a - b }.max, :<=, 1 / 28.0 + 1e-9, "하루에 하루치보다 더 내려간다"
    assert_equal 0.0, later.last
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

  # 코끼리는 흔적이고 아홉 자리는 안내다. 둘을 잇는 코드는 있을 수 없다.
  test "아홉 자리와 잇지 않는다" do
    elephant = Rails.root.join("app/models/elephant.rb").read
    assert_no_match(/abiding/i, elephant, "코끼리가 자리를 읽는다")

    sources = Rails.root.glob("app/**/*.{rb,erb,js}").map(&:read).join
    assert_no_match(/abiding[^\n]*Elephant|Elephant[^\n]*abiding/i, sources,
      "코끼리의 자리와 골라 둔 자리를 한 줄에서 잇는다")
    assert_no_match(/station[^\n]*abiding_id|abiding_id[^\n]*station|whiteness[^\n]*abiding/i, sources)
  end
end
