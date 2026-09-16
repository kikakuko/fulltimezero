# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 파장동 미륵당의 그 미륵. 하반신이 땅에 묻힌 상반신 도상이다.
# 비운 날마다 조금씩 올라온다. 열두 번이면 다 올라오고, 다시 묻히지 않는다.
#
# 절대 규칙:
#   - 숫자는 화면에 나가지 않는다. 「열둘 중 넷」은 만들지 않는다.
#     얼마나 드러났는지는 그림이 말한다.
#   - 오늘까지 비운 날만 센다. 앞으로 비워 둘 날은 그 날이 와야 올라온다.
#   - 도상은 말하지 않는다. 다 올라와도 웃거나 빛나지 않는다(SPIRIT §2).
class Maitreya
  # 열두 번이면 다 올라온다.
  FULL = 12

  Reading = Data.define(:rise, :before) do
    def risen? = rise >= 1.0
    def moved? = rise != before
  end

  def self.for(user, today: nil)
    today ||= user.today
    cleared = user.clearings.where(cleared_on: ..today).count

    Reading.new(rise: level(cleared), before: level(cleared - 1))
  end

  # 0 이 완전히 묻힘, 1 이 완전히 드러남. 사이는 곧게.
  def self.level(count)
    count.clamp(0, FULL) / FULL.to_f
  end
end
