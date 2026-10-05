# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 비운 날마다 땅 위로 드러난다. 스물넷이면 가슴까지 올라오고 다시 묻히지 않는다.
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

  test "흙 둔덕은 드러날수록 낮아진다" do
    mounds = (0..Maitreya::FULL).map { |count| Maitreya.at(count).mound }

    assert_equal mounds.sort.reverse, mounds
    assert_operator mounds.last, :<, mounds.first
  end

  test "스물넷이면 다 올라오고, 그 뒤로도 더 올라가지 않는다" do
    clear(30)

    assert_equal 0.70, Maitreya.for(@user).shown
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
    assert Maitreya.at(24).whole
    (2..23).each { |count| refute Maitreya.at(count).first || Maitreya.at(count).whole, "#{count}회에 한 줄이 뜬다" }
    refute Maitreya.at(0).first
  end

  # 숫자는 화면에 나가지 않는다. 세는 코드는 모델 하나뿐이다 —
  # 미륵을 그리는 쪽은 비율만 받고, 몇 번인지는 모른다.
  test "미륵을 그리는 쪽은 몇 번인지 모른다" do
    files = Rails.root.glob("app/{views,javascript,helpers}/**/*").select { |f| f.file? && f.read.include?("maitreya") }

    assert_not_empty files
    files.each do |file|
      assert_no_match(/\b(?:12|24)\b|열둘|스물넷|twelve|twenty-four|Maitreya::FULL|clearings\.count|\.count\b/, file.read,
                      "#{file.basename} 이 몇 번인지 안다")
    end
  end
end
