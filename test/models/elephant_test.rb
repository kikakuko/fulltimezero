# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 흰빛 — 지금까지 앉은 시간 하나에서 온다. 쌓이기만 하고, 끝에 닿지 않는다.
# 「몇 푼이냐」는 결이고(elephant_white_test), 「쌓이기만 한다」는 성질이라 여기 있다.
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

  test "앉지 않았으면 검다" do
    assert_equal 0.0, Elephant.for(@user).whiteness
  end

  test "앉은 시간이 쌓일수록 희어진다 — 단조롭게" do
    seen = [ Elephant.for(@user).whiteness ]

    [ 10, 30, 60, 120 ].each do |minutes|
      sit(minutes: minutes, on: @today)
      seen << Elephant.for(@user).whiteness
    end

    assert_equal seen.sort, seen, "앉았는데 흰빛이 내려갔다"
    assert_equal seen.uniq, seen, "앉았는데 흰빛이 그대로다"
  end

  test "끝에 닿지 않는다 — 몇 해를 앉아도 먹 한 점은 남는다" do
    sit(minutes: 60 * 1000, on: @today)

    assert_operator Elephant.for(@user).whiteness, :<, 1.0, "흰빛이 하나에 닿았다"
  end

  test "백오십 시간에 예순세 푼쯤 온다" do
    sit(minutes: 150 * 60, on: @today)

    assert_in_delta 1 - Math.exp(-1), Elephant.for(@user).whiteness, 1e-6
  end

  test "끝나지 않은 앉음은 세지 않는다" do
    @user.sittings.create!(mode: "sitting", sat_on: @today, created_at: 1.hour.ago)

    assert_equal 0.0, Elephant.for(@user).whiteness, "앉는 중에 벌써 희어졌다"
  end

  test "무위는 세지 않는다 — 형상이 풀리는 자리이지 몸이 쌓이는 자리가 아니다" do
    at = @today.in_time_zone(@user.time_zone).change(hour: 7)
    @user.sittings.create!(mode: "nothing", sat_on: @today, created_at: at, ended_at: at + 1.hour)

    assert_equal 0.0, Elephant.for(@user).whiteness
  end

  test "쉼 · 비움 · 사경은 코끼리를 움직이지 않는다 — 그것은 달과 미륵과 탑의 몫이다" do
    @user.rests.create!(rested_on: @today, duration: "a_while")
    @user.clearings.create!(cleared_on: @today)
    @user.copyings.create!(sutra_char: heart_sutra.chars.first, copied_on: @today, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    assert_equal 0.0, Elephant.for(@user).whiteness
  end

  test "뒤척임은 흰빛의 반대다 — 앉은 만큼 고요해진다" do
    before = Elephant.for(@user).restlessness
    sit(minutes: 600, on: @today)
    after = Elephant.for(@user).restlessness

    assert_operator after, :<, before, "앉았는데 뒤척임이 줄지 않았다"
    assert_in_delta 1 - Elephant.for(@user).whiteness, after, 1e-9
  end

  test "뒤척임은 바닥 아래로 내려가지 않는다 — 몇 해를 앉아도 한 점은 남는다" do
    sit(minutes: 60 * 5000, on: @today)

    assert_in_delta Elephant::RESTLESS_LEAST, Elephant.for(@user).restlessness, 1e-12
    assert_operator Elephant.for(@user).restlessness, :>, 0
  end

  test "앉지 않으면 그대로다 — 가만히 있어도 내려가지 않는다" do
    sit(minutes: 30, on: @today - 5)
    before = Elephant.for(@user)

    travel_to 40.days.from_now do
      after = Elephant.for(@user)
      assert_in_delta before.whiteness, after.whiteness, 1e-12
      assert_in_delta before.restlessness, after.restlessness, 1e-12
    end
  end

  private
    def sit(minutes:, on:)
      at = on.in_time_zone(@user.time_zone).change(hour: 7)
      @user.sittings.create!(mode: "sitting", sat_on: on, created_at: at, ended_at: at + minutes.minutes)
    end
end
