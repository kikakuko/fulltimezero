# This app is a raft. — 이 앱도 뗏목이다.
#
# 호스트는 셋이고 앱은 하나다 — 맨 이름 · www · app.
# www 는 맨 이름으로 넘기고, app 은 지금 쓰지 않아도 살려 둔다. 훗날 맨 이름에
# 소개나 강의가 들어와도 앱이 이사하지 않게 하려는 자리다.
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

  test "www 로 온 발길은 맨 이름으로 한 번 넘어간다" do
    with_env("APP_HOST", "example.com") do
      host! "www.example.com"
      get "/ko/privacy"

      assert_response :moved_permanently
      assert_equal "http://example.com/ko/privacy", response.headers["Location"]
    end
  end

  test "app 으로 온 발길은 넘기지 않는다 — 거기서 그대로 선다" do
    with_env("APP_HOST", "example.com") do
      host! "app.example.com"
      get "/ko/privacy"

      assert_response :success
    end
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
