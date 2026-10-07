# This app is a raft. — 이 앱도 뗏목이다.
#
# 염주 한 벌 — 꿰인 알을 읽는 자리. 쓰지 않는다.
#
# 숫자는 돌려주지 않는다. 몇 알인지는 코드 안의 수일 뿐, 화면에는 알만 보인다.
# 원(圓)은 백여덟 번째에 한 번만 닫힌다 — 매 절마다 뜨면 백여덟 번 되풀이되어
# 닳고, 도상이 넷이라 한 § 2 를 어긴다. 끝에 한 번, 염주가 닫히는 모양으로만.
class Rosary
  attr_reader :kind, :strung, :round

  def self.for(user, kind:)
    beads = user.beads.where(kind: kind)
    round = beads.maximum(:round) || 1
    strung = beads.where(round: round).count

    # 백여덟이 찼으면 다음 염주가 기다린다.
    round, strung = round + 1, 0 if strung >= Bowing::FULL

    new(kind: kind, round: round, strung: strung)
  end

  def initialize(kind:, round:, strung:)
    @kind = kind
    @round = round
    @strung = strung
  end

  def empty? = strung.zero?

  # 알이 놓이는 자리 — 원주 위의 자리. 꿰인 알만 그린다. 다 꿰이면 원이 닫힌다.
  # 첫 알은 맨 위에 놓이고 시계 방향으로 돈다.
  RADIUS = 50

  def beads
    (0...strung).map do |place|
      turn = place * 2 * Math::PI / Bowing::FULL
      { x: (RADIUS * Math.sin(turn)).round(2), y: (-RADIUS * Math.cos(turn)).round(2) }
    end
  end

  # 방금 닫혔는가 — 이 한 번만 원이 나타난다.
  def closed?(just_strung) = just_strung == Bowing::FULL
end
