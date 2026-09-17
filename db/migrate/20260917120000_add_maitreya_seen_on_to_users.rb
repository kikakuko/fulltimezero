# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵이 솟는 장면을 본 날. 하루 한 번은 브라우저가 아니라 그 사람에게 붙는다 — 한 기기를
# 둘이 써도 각자 제 장면을 보고, 쿠키를 지워도 같은 날 두 번 오지 않는다.
# 새로 모으는 것이 아니라 그 사람이 이미 한 일(오늘을 비워 둔 것)의 날짜다(§4).
class AddMaitreyaSeenOnToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :maitreya_seen_on, :date
  end
end
