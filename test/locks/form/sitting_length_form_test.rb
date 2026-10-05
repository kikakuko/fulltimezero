# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음의 길이의 결 — 낱말이 쉼의 길이와 겹치지 않는다.
require "test_helper"

class SittingLengthFormTest < ActiveSupport::TestCase
  test "낱말이 쉼의 길이와 겹치지 않는다" do
    assert_empty SittingLength::NAMES & Rest::DURATIONS,
      "앉음의 길이와 쉼의 길이가 같은 낱말을 쓴다. 환산으로 읽힐 여지를 두지 않는다."
  end
end
