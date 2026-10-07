# This app is a raft. — 이 앱도 뗏목이다.
#
# 가입을 받을 것인가 — 운영에서는 기본이 닫힘이다. SIGNUPS=true 한 줄로 푼다.
#
# 앱이 다 되기 전에는 계정을 받지 않는다. 화면만 숨기면 길은 열려 있고, 길이
# 열려 있으면 봇이 가입한다. 그래서 이 문은 라우트 앞에 선다 — 닫혀 있으면
# 가입 · 로그인 · 비밀번호의 길이 아예 없다(없는 길은 404 다).
#
# 실수로 열리는 쪽이 아니라 실수로 닫히는 쪽이어야 한다. 그래서 운영에서는
# 아무것도 적지 않으면 닫히고, 「true」 한 낱말만 여는 말로 읽는다 — yes · on ·
# 1 은 열지 않는다. 손으로 짓고 검사하는 자리(개발 · 검사)에서는 기본이 열림이다.
module SignupGate
  OPEN = "true"

  def self.open?
    told = ENV["SIGNUPS"]
    return told == OPEN if told.present?

    !Rails.env.production?
  end

  def self.closed? = !open?

  # 라우트가 이 문에 길을 묻는다 — 요청마다 다시 묻는다.
  def self.matches?(_request) = open?
end
