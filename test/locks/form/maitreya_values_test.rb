# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵의 값 — 묻힘의 네 단계(0.055 · 0.30 · 0.50 · 0.70)와 스물넷이라는 끝. 다시 잡을 수 있는
# 값이다. 「늘면 더 드러난다 · 줄지 않는다 · 끝에서 멈춘다」는 성질이라 기능 쪽이다
# (test/models/maitreya_test.rb).
require "test_helper"

class MaitreyaValuesTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    @today = @user.today
  end

  def clear(count, from: @today)
    count.times { |i| @user.clearings.create!(cleared_on: from - i) }
  end

  test "비운 날이 없으면 갓 끝만 — 흙 둔덕이 가장 높다" do
    reading = Maitreya.for(@user)

    assert_equal 0.055, reading.shown
    assert_equal Maitreya::MOUND_HIGH, reading.mound
  end

  test "묻힘의 단계 — 여섯에 갓과 이마, 열둘에 얼굴, 스물넷에 가슴까지" do
    { 0 => 0.055, 6 => 0.30, 12 => 0.50, 24 => 0.70 }.each do |count, shown|
      assert_equal shown, Maitreya.at(count).shown, "#{count}회"
    end
    assert_equal 24, Maitreya::FULL
  end

  test "초반은 빠르고 후반은 천천히 — 한 번에 드러나는 만큼이 줄어든다" do
    steps = (1..Maitreya::FULL).map { |count| Maitreya.at(count).shown - Maitreya.at(count - 1).shown }

    assert steps.all?(&:positive?), "비웠는데 드러나지 않는 날이 있다"
    assert_operator steps.first, :>, steps.last
    assert_operator steps[0...6].sum, :>, steps[12...24].sum, "첫 여섯이 마지막 열둘보다 덜 드러난다"
  end

  test "스물넷이면 다 올라오고, 그 뒤로도 더 올라가지 않는다" do
    clear(30)

    assert_equal 0.70, Maitreya.for(@user).shown
  end
end
