# This app is a raft. — 이 앱도 뗏목이다.
#
# 첫째 문에 다가오는 빛의 색은 때를 따른다. 매일 같으면 며칠 만에 벽지가
# 된다. 세는 것도 보상도 아니다 — 지금이 몇 시인지를 빛이 알 뿐이다.
# 어떤 빛을 보았는지 어디에도 적지 않는다.
#
# 계정이 없는 첫 방문에는 시간대를 모르므로 브라우저의 시계로 같은 경계를
# 쓴다(gates_controller.js 의 HOURS — 둘은 같아야 한다).
module GateLight
  HOURS = { dawn: 5...8, day: 8...17, evening: 17...20 }.freeze

  def self.at(hour)
    HOURS.find { |_, range| range.cover?(hour) }&.first || :night
  end
end
