# This app is a raft. — 이 앱도 뗏목이다.
#
# 염주 한 알. 절 한 배의 끝에 하나가 꿰인다.
#
# 절대 규칙:
#   - 한 배에 한 알. 앱이 세지 않는다 — 사람이 절하고 사람이 누른다.
#   - 얼마나 걸렸는지, 얼마나 숙였는지 적지 않는다. 잴 것이 없다(§3).
#   - 꿰인 알은 풀리지 않는다. 지우는 길을 두지 않는다 — 다 못 채우고 나가도
#     그 자리에 남는다(§3 쌓인 것은 무너지지 않는다).
#   - 백여덟이 차면 다음 염주가 시작된다. 못 채운 염주를 닦달하지 않는다.
class Bead < ApplicationRecord
  belongs_to :user

  validates :kind, inclusion: { in: Bowing::FORMS.keys }
  validates :round, numericality: { greater_than: 0 }
end
