# This app is a raft. — 이 앱도 뗏목이다.
#
# 미리 비워 둔 날. 달력에 옅은 원으로만 남는다.
#
# 비움은 약속이지 목표가 아니다. 지키지 못해도 아무 일도 일어나지
# 않는다 — 달성률도, 알림도, 되돌아보는 말도 없다(제1·3·4조).
class Clearing < ApplicationRecord
  belongs_to :user

  validates :cleared_on, presence: true, uniqueness: { scope: :user_id }
end
