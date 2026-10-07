# This app is a raft. — 이 앱도 뗏목이다.
#
# 절 — 두 벌. 한국식 큰절과 티베트식 오체투지.
#
# 고르는 것은 사람의 몫이다. 어느 쪽이 깊다거나 낫다고 말하지 않는다(§5).
# 고르는 자리에 설명을 쓰지 않는다 — 그림만 보이고 고른다(§2).
#
# 한 배는 칸으로 나뉘고, 칸은 보간하지 않고 툭 넘어간다(하드 컷). 칸마다
# 안내 한 줄이 함께 바뀐다 — 동작을 적은 글이고, 번호를 붙이지 않는다.
#
# 속도는 사람이 정한다. 앱은 칸을 넘길 뿐이고, 알은 사람이 누를 때 꿰인다.
# 못 따라간 사람에게 앱이 값을 매기면 그것이 §3 이 막는 판정이다.
module Bowing
  # 한 벌의 칸 수와 한 배의 길이.
  #
  # 칸마다의 머묾은 아직 그림에서 오지 않았다 — 지금은 고르게 나눈다.
  # 피그마에서 값이 오면 FORMS 의 holds 에 칸 수만큼 적는다. 그때
  # 고칠 곳은 여기 한 곳이다(화면도 자물쇠도 이 값을 읽는다).
  FORMS = {
    "korean" => { frames: 11, span: 18.0, holds: nil },
    "tibetan" => { frames: 12, span: 21.0, holds: nil }
  }.freeze

  # 염주 한 벌의 알. 백여덟.
  FULL = 108

  def self.form(kind) = FORMS[kind.to_s]

  def self.kind?(kind) = FORMS.key?(kind.to_s)

  # 칸마다 몇 초를 머무는가. 아직 값이 없으면 고르게 나눈다.
  def self.holds(kind)
    form = form(kind)
    form[:holds] || Array.new(form[:frames], (form[:span] / form[:frames]).round(2))
  end

  # 칸이 시작되는 때(초). 화면은 이것으로 칸을 넘긴다.
  def self.marks(kind)
    holds(kind).each_with_object([ 0.0 ]) { |hold, marks| marks << (marks.last + hold).round(2) }.first(form(kind)[:frames])
  end
end
