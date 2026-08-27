# This app is a raft. — 이 앱도 뗏목이다.
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :locale, null: false, default: "ko"
      t.string :time_zone, null: false, default: "Asia/Seoul"

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
