# This app is a raft. — 이 앱도 뗏목이다.
#
# 침묵 게이트 (SPIRIT 제4조).
#
# 이 앱에서 바깥으로 나가는 모든 소리와 모든 편지는 여기를 지난다.
# 게이트를 우회하는 경로는 코드에 존재할 수 없다 — 문서가 아니라
# 인터셉터와 테스트가 그것을 강제한다(test/integration/silence_test.rb).
#
# 유일한 기준:
#
#   부르지 않았는데 오는 것만이 알림이다.
#
# 비밀번호 재설정 편지는 사용자의 물음에 대한 답이지 앱의 말 걸기가
# 아니므로 알림이 아니다. 종성도 사용자가 그 자리에서 켜고 시작한
# 소리이므로 알림이 아니다.
class SilenceGate
  # 게이트가 승인하지 않은 발신이 나가려 할 때.
  class Bypass < StandardError; end

  # 게이트가 아는 발신. 여기 없는 이름은 조용히 통과하는 대신 터진다.
  #
  #   origin  :solicited   사용자가 방금 청한 응답
  #           :unsolicited 앱이 먼저 거는 말 — 언제나 차단
  #
  # unsolicited 목록은 비어 있다. 앞으로도 비어 있는 것이 목표다.
  # 여기에 무언가를 넣으려면 SPIRIT.md 개정이 먼저다.
  KINDS = {
    password_reset: { channel: :mail,  origin: :solicited },
    bell:           { channel: :sound, origin: :solicited }
  }.freeze

  # 침묵의 시각 — 사용자 시간대 기준.
  NIGHT_BEGINS = 22
  NIGHT_ENDS = 7

  # 침묵의 시각에도 울릴 수 있는 유일한 소리.
  ALWAYS_AUDIBLE = :bell

  # 게이트가 승인했다는 표식. 발송 직전에 헤더에서 지운다.
  STAMP = "X-Silence-Gate"

  class << self
    def allow?(kind, user: nil, at: Time.current)
      rule = rule_for(kind)

      return false unless rule[:origin] == :solicited
      return false if rule[:channel] == :sound && kind.to_sym != ALWAYS_AUDIBLE &&
                      silent_hours?(user, at: at)

      true
    end

    # 통과할 때만 블록이 실행된다.
    #
    # 이 메서드 안이 이 저장소에서 메일이 실제로 나가는 **유일한 지점**이다.
    # 다른 어디에도 deliver_now / deliver_later 가 있어서는 안 된다.
    def deliver(kind, user: nil, at: Time.current)
      return false unless allow?(kind, user: user, at: at)

      yield.deliver_later
      true
    end

    # 야간이거나, 앉아 있거나, 무위 중이면 침묵한다.
    def silent_hours?(user, at: Time.current)
      return false if user.nil?

      night?(user, at: at) || user.sitting?
    end

    def night?(user, at: Time.current)
      hour = at.in_time_zone(user.time_zone).hour
      hour >= NIGHT_BEGINS || hour < NIGHT_ENDS
    end

    def rule_for(kind)
      KINDS.fetch(kind.to_sym) do
        raise ArgumentError, "게이트가 모르는 발신이다: #{kind.inspect}"
      end
    end
  end
end
