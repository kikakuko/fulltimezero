# This app is a raft. — 이 앱도 뗏목이다.
#
# 검색에 보일 것인가. 기본은 「막음」이다 — 배포했다고 보여 줄 때가 된 것은 아니다.
# 사람을 부를 때가 되면 서버에서 SEARCHABLE=true 한 줄로 푼다. 그 한 줄이 robots.txt 와
# 화면의 noindex 를 함께 움직인다.
module SearchGate
  def self.open? = ActiveModel::Type::Boolean.new.cast(ENV["SEARCHABLE"]) == true
  def self.closed? = !open?
end
