# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음의 길이가 도는가 — 정함 없이 앉으면 끝이 없고, 모르는 이름은 기본값이 된다.
require "test_helper"

class SittingLengthTest < ActiveSupport::TestCase
  test "정함 없이 앉으면 정해진 끝이 없다" do
    length = SittingLength.new("open")

    assert length.open?
    assert_equal 0, length.seconds

    # 끝이 없으므로 앉은 만큼이 그대로 쌓인다. 달은 보름에 닿으면 머문다.
    assert_in_delta 3600, length.seconds_done(1.hour.ago), 2
  end

  test "모르는 이름은 조용히 기본값이 된다" do
    assert_equal SittingLength::DEFAULT, SittingLength.new("forever").name
    assert_equal SittingLength::DEFAULT, SittingLength.new(nil).name
  end

  test "새로고침해도 달이 처음부터 다시 차오르지 않는다" do
    length = SittingLength.new("tea")

    assert_equal 0, length.seconds_done(Time.current)
    assert_in_delta 180, length.seconds_done(3.minutes.ago), 2

    # 길이를 넘겨도 넘치지 않는다. 보름에 닿으면 그대로 머문다.
    assert_equal length.seconds, length.seconds_done(1.day.ago)
  end
end
