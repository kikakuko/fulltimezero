# This app is a raft. — 이 앱도 뗏목이다.
#
# 탑. 사경한 자가 한 칸씩 쌓인 것이다.
#
# 탑은 무너지지 않는다(SPIRIT §3). 이 객체에는 탑을 낮추는 길이 없다 —
# 쌓인 칸을 셀 뿐, 시간이 흘렀다고 무엇을 덜어 내지 않는다.
# 높이는 화면에 숫자로 내보이지 않는다. 얼마나 쌓였는지는 탑이 말한다.
class Pagoda
  attr_reader :user, :sutra

  def self.for(user, sutra: Sutra.heart) = new(user, sutra)

  def initialize(user, sutra)
    @user = user
    @sutra = sutra
  end

  # 마지막으로 쓴 자리. 아직 한 자도 쓰지 않았으면 영.
  def last_pos
    user.copyings.joins(:sutra_char)
        .where(sutra_chars: { sutra_id: sutra.id })
        .maximum("sutra_chars.pos").to_i
  end

  # 다음에 쓸 자. 경을 다 쓰면 없다.
  def next_char = sutra.chars.find_by(pos: last_pos + 1)

  def complete? = last_pos >= sutra.total
end
