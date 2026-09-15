# This app is a raft. — 이 앱도 뗏목이다.
#
# 세션에 남아 있던 IP 주소와 브라우저 정보를 지우고, 다시는 담을 수 없게
# 칸 자체를 걷어낸다. Rails 인증 생성기의 기본값이 그대로 남아, 개인정보
# 처리방침의 「이메일 하나만 받는다」가 거짓인 상태였다.
class ForgetWhereSessionsCameFrom < ActiveRecord::Migration[8.1]
  def up
    # 칸을 걷어내기 전에 값부터 비운다. 걷어내면 함께 사라지지만,
    # 지우는 일이 무엇인지 이 파일에 분명히 남기기 위해서다.
    execute "UPDATE sessions SET ip_address = NULL, user_agent = NULL"

    remove_column :sessions, :ip_address
    remove_column :sessions, :user_agent
  end

  # 되돌려도 칸만 돌아온다. 지운 값은 돌아오지 않는다.
  def down
    add_column :sessions, :ip_address, :string
    add_column :sessions, :user_agent, :string
  end
end
