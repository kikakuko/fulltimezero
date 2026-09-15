# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경은 언제나 쓴 글씨다.
#
# 「종이에 썼다」는 §3 이 화면 서예 입력을 막던 때의 절충안이었다. §3 이
# 「화면은 종이로 가는 문이다」로 개정되어 화면 사경이 정당해지자 절충안은
# 목적을 잃었다. 확인할 수 없는 선언이라 누르기만 하면 탑이 서고, 그 탑은
# 자기 글씨가 아니라 활자뿐이게 된다. 그래서 버튼을 걷어내고, 획 없는
# 사경이 다시 생기지 않게 칸을 비울 수 없게 한다.
#
# 이렇게 올린 기록은 개발 데이터에도 없었고 운영은 아직 없다. 있었다면
# 이 마이그레이션은 여기서 멈추고 터진다 — 사용자의 기록을 조용히 지우지
# 않기 위해서다.
class CopyingsAreAlwaysWritten < ActiveRecord::Migration[8.1]
  def up
    if select_value("SELECT COUNT(*) FROM copyings WHERE glyph_paths IS NULL").to_i.positive?
      raise ActiveRecord::IrreversibleMigration, "종이에 썼다고 올린 사경이 있다. 지우지 말고 먼저 어떻게 둘지 정하라."
    end

    change_column_null :copyings, :glyph_paths, false
  end

  def down
    change_column_null :copyings, :glyph_paths, true
  end
end
