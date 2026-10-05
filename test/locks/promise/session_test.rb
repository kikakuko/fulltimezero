# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 개인정보 처리방침은 「이메일 하나만 받는다」고 말한다(SPIRIT §4).
# 세션은 누구의 것인지만 알고, 어디서 무엇으로 들어왔는지는 모른다.
class SessionTest < ActiveSupport::TestCase
  test "세션에는 누구의 것인지 말고 아무것도 적지 않는다" do
    assert_equal %w[created_at id updated_at user_id], Session.column_names.sort
  end

  test "앱 코드 어디에도 IP 를 들여다보는 곳이 없다" do
    # 왜 보지 않는지를 적은 주석은 걷어내고 코드만 본다.
    offenders = %w[app lib config].flat_map { |dir| Rails.root.join(dir).glob("**/*.rb") }
      .select { |path| path.read.gsub(/^\s*#.*$/, "").match?(/\bremote_ip\b|\bip_address\b/) }

    assert_empty offenders.map { |path| path.relative_path_from(Rails.root).to_s },
      "IP 를 보는 코드가 들어왔다. 이메일 말고는 모으지 않는다."
  end

  test "시도를 세는 모든 자리가 IP 대신 이메일을 센다" do
    controllers = Rails.root.join("app/controllers").glob("*.rb").select { |path| path.read.include?("rate_limit") }

    assert_not_empty controllers
    controllers.each do |path|
      assert_match(/rate_limit .*by: :throttle_key/, path.read,
        "#{path.basename} 이 기본값(IP)으로 시도를 센다")
    end
  end

  test "캐시에 남는 것은 이메일이 아니라 지문이다" do
    key = Throttling.fingerprint("  One@Example.com ")

    assert_equal Throttling.fingerprint("one@example.com"), key, "대소문자·공백에 따라 따로 세어진다"
    assert_not_includes key, "example", "이메일이 날것으로 캐시에 남는다"
  end
end
