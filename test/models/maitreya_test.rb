# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 비운 날마다 조금씩 올라온다. 열두 번이면 다 올라오고 다시 묻히지 않는다.
require "test_helper"

class MaitreyaTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    @today = @user.today
  end

  test "비운 날이 없으면 완전히 묻혀 있다" do
    assert_equal 0.0, Maitreya.for(@user).rise
  end

  test "비운 날마다 곧게 올라온다" do
    4.times { |i| @user.clearings.create!(cleared_on: @today - i) }

    assert_in_delta 4 / 12.0, Maitreya.for(@user).rise, 1e-9
    assert_in_delta 3 / 12.0, Maitreya.for(@user).before, 1e-9
  end

  test "열두 번이면 다 올라오고, 그 뒤로도 더 올라가지 않는다" do
    14.times { |i| @user.clearings.create!(cleared_on: @today - i) }
    reading = Maitreya.for(@user)

    assert_equal 1.0, reading.rise
    assert reading.risen?
  end

  test "앞으로 비워 둘 날은 그 날이 와야 올라온다" do
    @user.clearings.create!(cleared_on: @today + 3)

    assert_equal 0.0, Maitreya.for(@user).rise
    assert_in_delta 1 / 12.0, Maitreya.for(@user, today: @today + 3).rise, 1e-9
  end

  test "오늘 비웠으면 어제보다 한 뼘 올라와 있다" do
    @user.clearings.create!(cleared_on: @today)
    reading = Maitreya.for(@user)

    assert reading.moved?
    assert_in_delta 1 / 12.0, reading.rise - reading.before, 1e-9
  end

  # 숫자는 화면에 나가지 않는다. 세는 코드는 여기 하나뿐이다 —
  # 미륵을 그리는 쪽은 얼마나 올라왔는지(0 ~ 1)만 받고, 몇 번인지는 모른다.
  test "미륵을 그리는 쪽은 열둘을 모른다" do
    files = Rails.root.glob("app/{views,javascript,helpers}/**/*").select { |f| f.file? && f.read.include?("maitreya") }

    assert_not_empty files
    files.each do |file|
      assert_no_match(/\b12\b|열둘|twelve|Maitreya::FULL|clearings\.count/, file.read, "#{file.basename} 이 열둘을 안다")
    end
  end
end
