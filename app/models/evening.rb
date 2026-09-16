# This app is a raft. — 이 앱도 뗏목이다.
#
# 바쁜 날 저녁의 한마디.
#
# 대개는 「바쁜 하루였다…」이고, 이레에 한두 번은 무원(無願)의 줄이 온다 —
# 삼해탈문의 셋째 문, 바라는 바 없음 · 향하는 바 없음. 『금강경』의
# 무주상보시(無住相布施)가 같은 자리다.
#
# 응원이 아니라 서술이다. 「바라는 바 없이 한다」를 「바라지 말라」로
# 바꾸면 그것은 명령이 되고, 명령은 이 앱의 말이 아니다.
#
# 같은 날 같은 사람에게는 늘 같은 줄이 오도록 날짜에서 뽑는다 —
# 새로고침할 때마다 바뀌면 그것은 한마디가 아니라 뽑기다(Greeting 과 같다).
class Evening
  USUAL = "days.evening"
  WITHOUT_AIM = %w[doer aim wish].freeze

  # 이레 중 이틀쯤 — 계절 인사와 같은 빈도. 온기는 빈도가 낮을수록 진하다.
  ODDS = 2
  IN = 7

  def self.line_for(user, on: nil)
    date = on || user.today
    seed = Digest::MD5.hexdigest("evening:#{user.id}:#{date}")[0, 8].to_i(16)

    return USUAL unless seed % IN < ODDS

    "days.without_aim.#{WITHOUT_AIM[seed / IN % WITHOUT_AIM.size]}"
  end
end
