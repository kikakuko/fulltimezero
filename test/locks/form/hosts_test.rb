# This app is a raft. — 이 앱도 뗏목이다.
#
# 주소는 하나다 — 맨 이름. www 와 app 은 받되 맨 이름으로 넘긴다(301). 그래야 세션 쿠키가
# 맨 이름 하나에만 걸리고 쿠키 범위를 고민할 일이 없다(2026-10-14). app 을 훗날의 앱 자리로
# 살려 두던 것은 접었다 — 맨 이름에 소개가 들어오는 날이 오면 그때 다시 정한다.
# 「결」 쪽이다 — 어디에 무엇을 둘지는 바뀔 수 있다. 다만 셋 밖의 주소는 받지 않는다.
require "test_helper"

class HostsTest < ActionDispatch::IntegrationTest
  test "운영이 받는 주소는 셋뿐이다 — 맨 이름 · www · app" do
    production = Rails.root.join("config/environments/production.rb").read

    assert_match(/\[ "", "www\.", "app\." \]/, production, "받는 주소가 셋이 아니다")
  end

  test "프록시도 같은 셋에 인증서를 받는다" do
    deploy = Rails.root.join("config/deploy.yml").read

    assert_match(/hosts:\s*\n\s*- <%= ENV\.fetch\("APP_HOST"\) %>\s*\n\s*- www\.<%= ENV\.fetch\("APP_HOST"\) %>\s*\n\s*- app\.<%= ENV\.fetch\("APP_HOST"\) %>/,
      deploy, "프록시의 호스트가 셋이 아니다")
  end

  test "www 와 app 으로 온 발길은 맨 이름으로 한 번 넘어간다" do
    with_env("APP_HOST", "example.com") do
      %w[www app].each do |sub|
        host! "#{sub}.example.com"
        get "/ko/privacy"

        assert_response :moved_permanently, "#{sub} 가 맨 이름으로 넘어가지 않는다"
        assert_equal "http://example.com/ko/privacy", response.headers["Location"]
      end
    end
  end

  # 쿠키는 맨 이름 하나에만 — Domain 속성 없이 호스트에만 걸린다. www 와 app 은 넘기므로
  # 거기서 쿠키가 심길 일이 없다.
  test "세션 쿠키는 맨 이름 하나에만 걸린다 — Domain 을 넓히지 않는다" do
    with_env("APP_HOST", "example.com") do
      host! "example.com"
      # 세션은 적을 때 심긴다 — 계정 없이 둘째 문에 한 줄을 적으면 세션이 든다.
      patch "/ko/threshold/naming", params: { user: { what_moves: "바람" } }

      set_cookie = Array(response.headers["set-cookie"]).join("\n")
      assert_match(/_fulltimezero_session/, set_cookie, "세션 쿠키가 없다")
      assert_no_match(/domain=/i, set_cookie, "세션 쿠키의 Domain 이 넓다")
    end
    assert_no_match(/domain:/, Rails.root.glob("config/initializers/*.rb").map(&:read).join, "세션 저장소에 Domain 을 걸었다")
  end

  private
    def with_env(name, value)
      was = ENV[name]
      ENV[name] = value
      yield
    ensure
      ENV[name] = was
    end
end
