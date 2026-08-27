# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class MoonPhaseTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @today = Date.new(2026, 8, 27)
  end

  test "삭: 기록이 없으면 달은 비어 있다" do
    assert_equal 0.0, phase.fraction
    assert phase.new_moon?
  end

  test "하루 기록하면 창의 한 칸이 찬다" do
    rest_on @today
    assert_in_delta 1.0 / 28, phase.fraction, 0.0001
  end

  test "망: 스물여드레를 모두 기록하면 달이 가득 찬다" do
    28.times { |i| rest_on @today - i }
    assert_equal 1.0, phase.fraction
    assert phase.full_moon?
  end

  test "창의 경계: 스물여드레째 날은 들어오고 그 하루 앞은 밀려난다" do
    rest_on @today - 27
    assert_in_delta 1.0 / 28, phase.fraction, 0.0001

    Rest.delete_all
    rest_on @today - 28
    assert_equal 0.0, phase.fraction
  end

  test "연속기록이 아니다: 사이가 비어도 남은 기록은 그대로 센다" do
    rest_on @today
    rest_on @today - 10
    rest_on @today - 20
    assert_in_delta 3.0 / 28, phase.fraction, 0.0001
  end

  test "하루에 몇 번을 기록하든 그 날은 한 번으로 센다" do
    3.times { rest_on @today }
    assert_in_delta 1.0 / 28, phase.fraction, 0.0001
  end

  test "쉼의 결에는 위계가 없다: 어떤 결이든 같은 무게다" do
    fractions = Rest::TEXTURES.map do |texture|
      Rest.delete_all
      rest_on @today, texture: texture
      phase.fraction
    end

    Rest.delete_all
    rest_on @today, texture: nil
    fractions << phase.fraction

    assert_equal 1, fractions.uniq.size, "결에 따라 달이 다르게 찼다"
  end

  test "길이에도 위계가 없다: 한 호흡과 시간을 잊었다가 같은 무게다" do
    fractions = Rest::DURATIONS.map do |duration|
      Rest.delete_all
      rest_on @today, duration: duration
      phase.fraction
    end

    assert_equal 1, fractions.uniq.size, "길이에 따라 달이 다르게 찼다"
  end

  # 달은 쉼 기록과 앉음, 두 곳을 함께 본다.
  test "앉기만 해도 그 날은 찬다" do
    sit_on @today

    assert_in_delta 1.0 / 28, phase.fraction, 0.0001
  end

  test "쉼만 있는 날 · 앉음만 있는 날 · 둘 다 있는 날의 무게가 같다" do
    rest_on @today
    only_rest = phase.fraction

    Rest.delete_all
    sit_on @today
    only_sitting = phase.fraction

    rest_on @today
    both = phase.fraction

    assert_equal [ only_rest ], [ only_sitting, both ].uniq,
      "쉼과 앉음의 무게가 다르다. 어느 쪽도 다른 쪽보다 무겁지 않다."
    assert_in_delta 1.0 / 28, both, 0.0001
  end

  test "명상이든 무위든 앉음의 갈래에는 위계가 없다" do
    fractions = Sitting::MODES.map do |mode|
      Sitting.delete_all
      sit_on @today, mode: mode
      phase.fraction
    end

    assert_equal 1, fractions.uniq.size, "앉음의 갈래에 따라 달이 다르게 찼다"
  end

  test "하루에 몇 번을 앉든 그 날은 한 번으로 센다" do
    3.times { sit_on @today }

    assert_in_delta 1.0 / 28, phase.fraction, 0.0001
  end

  test "자취는 스물여드레 칸이고 마지막 칸이 오늘이다" do
    assert_equal MoonPhase::WINDOW_DAYS, phase.days.size
    assert_equal @today, phase.days.last.date
    assert_equal 4, phase.rows.size
  end

  test "오늘의 경계는 사용자의 시간대를 따른다" do
    seoul = users(:one)      # Asia/Seoul
    new_york = users(:two)   # America/New_York

    travel_to Time.utc(2026, 8, 27, 22, 0) do
      assert_equal Date.new(2026, 8, 28), seoul.today
      assert_equal Date.new(2026, 8, 27), new_york.today
    end
  end

  private
    def phase
      MoonPhase.for(@user, today: @today)
    end

    def rest_on(date, texture: "did_nothing", duration: "a_moment")
      @user.rests.create!(rested_on: date, texture: texture, duration: duration)
    end

    def sit_on(date, mode: "sitting")
      @user.sittings.create!(sat_on: date, mode: mode)
    end
end
