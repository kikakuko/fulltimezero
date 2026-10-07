# This app is a raft. — 이 앱도 뗏목이다.
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # 손님은 세션이 없다 — 쿠키도 남기지 않는다. 씨앗을 함께 볼 뿐이다.
  attribute :guest

  def self.user = session&.user || guest
end
