# This app is a raft. — 이 앱도 뗏목이다.
#
# 인용의 결 — 경의 말을 어떤 색으로 세우는가. 바탕이 밝으면 황토가 읽히지 않아 먹으로
# 선다. 「출전 없이 서지 않는다」는 약속 쪽이다 — test/locks/promise/verse_promise_test.rb.
require "test_helper"

class VerseFormTest < ActionDispatch::IntegrationTest
  test "밝은 바탕의 경의 말은 먹으로 선다 — 첫째 문" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.threshold__verse \{[^}]*color: var\(--ink\);/, css, "첫째 문의 경의 말이 먹이 아니다")
  end
end
