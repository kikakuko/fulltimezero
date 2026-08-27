# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class SilenceGateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.update!(time_zone: "Asia/Seoul")
  end

  test "게이트가 모르는 발신은 조용히 통과하지 않고 터진다" do
    assert_raises(ArgumentError) { SilenceGate.allow?(:welcome_back, user: @user) }
    assert_raises(ArgumentError) { SilenceGate.allow?(:streak_broken, user: @user) }
  end

  test "부르지 않았는데 오는 것은 알림이므로 언제나 막힌다" do
    unsolicited = { channel: :mail, origin: :unsolicited }

    stubbing(SilenceGate, :rule_for, unsolicited) do
      refute SilenceGate.allow?(:whatever, user: @user, at: noon),
        "앱이 먼저 거는 말이 게이트를 지났다"
    end
  end

  test "종성이 아닌 소리는 침묵의 시각에 나지 않는다" do
    some_sound = { channel: :sound, origin: :solicited }

    stubbing(SilenceGate, :rule_for, some_sound) do
      assert SilenceGate.allow?(:some_sound, user: @user, at: noon)
      refute SilenceGate.allow?(:some_sound, user: @user, at: night), "야간에 소리가 났다"

      stubbing(@user, :sitting?, true) do
        refute SilenceGate.allow?(:some_sound, user: @user, at: noon), "앉는 중에 소리가 났다"
      end
    end
  end

  test "지금 게이트가 아는 발신은 모두 사용자가 청한 것뿐이다" do
    origins = SilenceGate::KINDS.values.map { _1[:origin] }.uniq

    assert_equal [ :solicited ], origins,
      "앱이 먼저 거는 말이 게이트 목록에 들어왔다. SPIRIT 제4조 개정이 먼저다."
  end

  test "사용자가 청한 편지는 야간에도 나간다" do
    assert SilenceGate.allow?(:password_reset, user: @user, at: night)
  end

  test "종성은 침묵의 시각에도 울린다 — 사용자가 그 자리에서 켠 소리다" do
    assert SilenceGate.allow?(:bell, user: @user, at: night)

    stubbing(@user, :sitting?, true) do
      assert SilenceGate.allow?(:bell, user: @user, at: noon)
    end
  end

  test "야간의 경계는 사용자 시간대를 따른다" do
    here = users(:one)
    here.update!(time_zone: "Asia/Seoul")
    there = users(:two)
    there.update!(time_zone: "Europe/Lisbon")

    # 서울의 밤이 리스본의 낮인 순간.
    at = Time.utc(2026, 8, 27, 14, 0) # 서울 23시, 리스본 15시

    assert SilenceGate.night?(here, at: at)
    refute SilenceGate.night?(there, at: at)
  end

  test "밤이 시작되고 끝나는 자리" do
    refute SilenceGate.night?(@user, at: seoul(21, 59))
    assert SilenceGate.night?(@user, at: seoul(22, 0))
    assert SilenceGate.night?(@user, at: seoul(6, 59))
    refute SilenceGate.night?(@user, at: seoul(7, 0))
  end

  test "앉아 있는 동안은 침묵의 시각이다" do
    refute SilenceGate.silent_hours?(@user, at: noon)

    stubbing(@user, :sitting?, true) do
      assert SilenceGate.silent_hours?(@user, at: noon)
    end
  end

  test "통과하지 못하면 블록은 아예 실행되지 않는다" do
    ran = false

    stubbing(SilenceGate, :allow?, false) do
      SilenceGate.deliver(:password_reset, user: @user) { ran = true }
    end

    refute ran, "막힌 발신의 블록이 실행되었다"
  end

  private
    def seoul(hour, minute) = ActiveSupport::TimeZone["Asia/Seoul"].local(2026, 8, 27, hour, minute)
    def night = seoul(23, 30)
    def noon = seoul(12, 0)
end
