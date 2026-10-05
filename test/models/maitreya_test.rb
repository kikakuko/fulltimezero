# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵이 도는가 — 비운 날이 늘면 더 드러나고, 줄지 않고, 끝에서 멈춘다. 성질만 본다.
# 0.055 · 0.30 · 0.50 · 0.70 이라는 값은 결 쪽이다(test/locks/form/maitreya_values_test.rb) —
# 나중에 값을 다시 잡아도 여기는 깨지지 않아야 한다.
require "test_helper"

class MaitreyaTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    @today = @user.today
  end

  def clear(count, from: @today)
    count.times { |i| @user.clearings.create!(cleared_on: from - i) }
  end

  test "비운 날이 늘면 더 드러난다 — 한 번도 줄지 않는다" do
    shown = (0..Maitreya::FULL).map { |count| Maitreya.at(count).shown }

    assert_equal shown.sort, shown, "비웠는데 도로 묻히는 날이 있다"
    assert_equal shown.uniq, shown, "비웠는데 그대로인 날이 있다"
    assert_operator shown.last, :>, shown.first
  end

  test "끝에서 멈춘다 — 다 올라온 뒤로는 더 올라가지 않는다" do
    clear(Maitreya::FULL + 6)

    assert_equal Maitreya.at(Maitreya::FULL).shown, Maitreya.for(@user).shown
    assert_equal Maitreya.at(Maitreya::FULL).shown, Maitreya.at(Maitreya::FULL * 2).shown
  end

  test "흙 둔덕은 드러날수록 낮아진다" do
    mounds = (0..Maitreya::FULL).map { |count| Maitreya.at(count).mound }

    assert_equal mounds.sort.reverse, mounds
    assert_operator mounds.last, :<, mounds.first
  end

  test "앞으로 비워 둘 날은 그 날이 와야 올라온다" do
    @user.clearings.create!(cleared_on: @today + 3)

    assert_equal 0.055, Maitreya.for(@user).shown
    assert_equal Maitreya.at(1).shown, Maitreya.for(@user, today: @today + 3).shown
  end

  # 장면은 선언하는 그 순간의 것이다 — 누르기 전과 뒤를 함께 건넨다.
  test "선언하기 전과 뒤 — 오늘 이미 비웠으면 장면이 없다" do
    clear(3, from: @today - 1)
    before, after = Maitreya.declaring(@user)

    assert_equal Maitreya.at(3), before
    assert_equal Maitreya.at(4), after

    @user.clearings.create!(cleared_on: @today)
    assert_nil Maitreya.declaring(@user)
  end

  test "한 줄과 지용은 처음 비운 날과 다 올라온 날에만" do
    assert Maitreya.at(1).first
    assert Maitreya.at(Maitreya::FULL).whole
    (2...Maitreya::FULL).each { |count| refute Maitreya.at(count).first || Maitreya.at(count).whole, "#{count}회에 한 줄이 뜬다" }
    refute Maitreya.at(0).first
  end
end
