# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class SittingTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  # 앉음에 남는 것은 "그 날 앉았다"는 사실뿐이다.
  # 길이·분·완주·점수 컬럼이 뒷문으로 들어오지 못하게 목록을 못박는다.
  test "컬럼 목록은 이것뿐이다" do
    assert_equal %w[created_at ended_at id mode sat_on updated_at user_id],
      Sitting.column_names.sort
  end

  test "길이도 분도 저장하지 않는다" do
    forbidden = /minute|second|duration|length|seconds|score|rating|quality|complete|streak/i

    Sitting.column_names.each do |column|
      assert_no_match forbidden, column, "앉음에 #{column} 이 생겼다"
    end
  end

  test "앉으면 그 날짜가 사용자 시간대로 찍힌다" do
    sitting = @user.sittings.create!(mode: "sitting")

    assert_equal @user.today, sitting.sat_on
  end

  test "끝나지 않은 자리는 앉는 중이다" do
    @user.sittings.create!(mode: "nothing")

    assert @user.sitting?
  end

  test "오래된 자리는 끝난 것으로 본다 — 앱이 영영 침묵하지 않도록" do
    sitting = @user.sittings.create!(mode: "nothing")
    sitting.update_columns(created_at: (Sitting::STALE_AFTER + 1.hour).ago)

    refute @user.sitting?
  end

  test "마치면 끝난 시각이 남고, 다시 마쳐도 그 시각은 흔들리지 않는다" do
    sitting = @user.sittings.create!(mode: "sitting")
    sitting.finish!
    first = sitting.ended_at

    sitting.finish!

    assert_equal first, sitting.reload.ended_at
  end

  test "모르는 갈래로는 앉을 수 없다" do
    refute @user.sittings.new(mode: "practice").valid?
  end
end
