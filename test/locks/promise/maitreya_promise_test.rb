# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵의 약속 — 세는 것은 모델 하나뿐이다. 그리는 쪽은 비율만 받고 몇 번인지 모른다.
# 그려야 「스물셋 번째」 같은 말이 화면에 설 길이 없다(사람을 재지 않는다).
require "test_helper"

class MaitreyaPromiseTest < ActiveSupport::TestCase

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
