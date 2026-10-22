# This app is a raft. — 이 앱도 뗏목이다.
#
# 서버가 바깥을 부르지 않는다(docs/legal/none.md 의 「AI 가 없다」, SPIRIT §6). 젬과 pin 은
# dependency_test · importmap_test 가 수로 막는다. 남은 길은 서버가 바깥 API 를 직접 부르는
# 것이다 — app/ 에 HTTP 로 바깥을 부르는 코드가 메일러 밖에 없음을 잠근다. 메일도 SilenceGate
# 를 지난다(silence_test).
require "test_helper"

class OutwardCallTest < ActiveSupport::TestCase
  CALLS = /Net::HTTP|URI\.open|\bFaraday\b|\bHTTParty\b|require\s+["']open-uri["']/

  test "app/ 에서 바깥을 부르는 코드가 메일러 밖에 없다" do
    offenders = Rails.root.glob("app/**/*.rb").reject { |path| path.to_s.include?("/app/mailers/") }
                    .select { |path| path.read.match?(CALLS) }

    assert_empty offenders.map { |path| path.relative_path_from(Rails.root).to_s },
      "서버가 바깥을 부른다 — Net::HTTP · URI.open · Faraday · HTTParty 는 메일러 밖에 둘 수 없다"
  end
end
