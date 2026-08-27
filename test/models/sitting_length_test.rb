# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class SittingLengthTest < ActiveSupport::TestCase
  test "낱말이 쉼의 길이와 겹치지 않는다" do
    assert_empty SittingLength::NAMES & Rest::DURATIONS,
      "앉음의 길이와 쉼의 길이가 같은 낱말을 쓴다. 환산으로 읽힐 여지를 두지 않는다."
  end

  test "정함 없이 앉으면 기울 것이 없다" do
    length = SittingLength.new("open")

    assert length.open?
    assert_equal 0, length.seconds
    assert_equal 0, length.seconds_left(1.hour.ago)
  end

  test "모르는 이름은 조용히 기본값이 된다" do
    assert_equal SittingLength::DEFAULT, SittingLength.new("forever").name
    assert_equal SittingLength::DEFAULT, SittingLength.new(nil).name
  end

  test "새로고침해도 처음부터 다시 시작하지 않는다" do
    length = SittingLength.new("tea")

    assert_equal length.seconds, length.seconds_left(Time.current)
    assert_operator length.seconds_left(3.minutes.ago), :<, length.seconds
    assert_equal 0, length.seconds_left(1.day.ago)
  end
end
