# This app is a raft. — 이 앱도 뗏목이다.
#
# 인용 표의 결 — 허락 칸에 올 수 있는 값은 셋뿐이다. 「남의 말에는 허락이 있어야
# 한다」는 약속이고(test/locks/promise/citation_test.rb), 어떤 낱말로 적는지는 결이다.
require "test_helper"

class CitationFormTest < ActiveSupport::TestCase
  test "허락의 값은 CC0 · CC BY-NC · own 가운데 하나이거나 비어 있다" do
    assert_equal [ "CC0", "CC BY-NC", "own" ], Citation::LICENSES

    Citation::CHECKED.each do |key, row|
      assert_includes Citation::LICENSES + [ nil, "" ], row[:license],
        "#{key} 의 허락 값이 셋 밖이다: #{row[:license].inspect}"
    end
  end

  test "남의 말에 붙는 허락은 둘뿐이다 — own 은 우리 것에만" do
    assert_equal [ "CC0", "CC BY-NC" ], Citation::BORROWABLE
  end
end
