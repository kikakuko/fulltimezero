# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 파장동 미륵당의 그 미륵. 하반신이 땅에 묻힌 상반신 도상이다.
# 비운 날마다 조금씩 땅 위로 드러난다. 스물넷이면 가슴까지 올라오고 — 파장동
# 미륵의 실제 모습 — 다시 묻히지 않는다. 반년쯤 걸린다.
#
# 절대 규칙:
#   - 숫자는 화면에 나가지 않는다. 「스물넷 중 다섯」은 만들지 않는다.
#     얼마나 드러났는지는 그림이 말한다. 그리는 쪽은 비율만 받는다.
#   - 오늘까지 비운 날만 센다. 앞으로 비워 둘 날은 그 날이 와야 올라온다.
#   - 도상은 말하지 않는다. 다 올라와도 웃거나 빛나지 않는다(SPIRIT §2).
class Maitreya
  FULL = 24

  # 비운 날 수 → 그림이 땅 위로 드러난 비율. 초반은 빠르고 후반은 천천히
  # (ease-out) — 첫 달에 흙 둔덕만 보면 답답하다. 사이는 곧게 잇는다.
  #   0 갓 끝만 · 6 갓이 다 나온다 · 12 얼굴이 나온다 · 24 가슴까지
  STAGES = { 0 => 0.055, 6 => 0.28, 12 => 0.38, 24 => 0.50 }.freeze

  # 흙 둔덕은 드러날수록 낮아진다 — 미륵이 흙을 밀어 올리며 나온다.
  MOUND_HIGH = 1.0
  MOUND_LOW = 0.2

  # shown 드러난 비율 · mound 둔덕의 높이(0 ~ 1)
  # first 처음 비운 날 · whole 다 올라온 날 — 한 줄과 지용(地涌)은 이 두 날의 것이다.
  Reading = Data.define(:shown, :mound, :first, :whole)

  def self.for(user, today: nil)
    today ||= user.today

    at(user.clearings.where(cleared_on: ..today).count)
  end

  # 「오늘을 비워 둔다」를 누르기 전과 뒤. 오늘 이미 비웠으면 없다 — 장면은
  # 선언하는 그 순간의 것이다.
  def self.declaring(user)
    return if user.cleared_today?

    count = user.clearings.where(cleared_on: ..user.today).count
    [ at(count), at(count + 1) ]
  end

  def self.at(count)
    count = count.clamp(0, FULL)

    Reading.new(shown: shown(count), mound: mound(count), first: count == 1, whole: count == FULL)
  end

  def self.shown(count)
    (from, low), (to, high) = STAGES.each_cons(2).find { |(a, _), (b, _)| count.between?(a, b) }

    (low + (high - low) * (count - from) / (to - from).to_f).round(4)
  end

  def self.mound(count)
    (MOUND_HIGH - (MOUND_HIGH - MOUND_LOW) * count / FULL.to_f).round(4)
  end
end
