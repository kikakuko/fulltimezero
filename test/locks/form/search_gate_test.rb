# This app is a raft. — 이 앱도 뗏목이다.
#
# 검색에 보일 것인가 — 기본은 「막음」이다. 배포했다고 보여 줄 때가 된 것은 아니다.
# 사람을 부를 때가 되면 서버에서 SEARCHABLE=true 한 줄로 푼다. 「결」 쪽 자물쇠다 —
# 보여 줄 때가 되면 풀린다. 다만 기본값이 막음인 것은 손대지 않는다.
require "test_helper"

class SearchGateTest < ActionDispatch::IntegrationTest
  test "기본은 막음이다 — 설정이 없으면 로봇에게 전부 막고 화면에 noindex 를 둔다" do
    assert SearchGate.closed?, "기본값이 막음이 아니다"

    get robots_path
    assert_equal "User-agent: *\nDisallow: /\n", response.body

    get new_session_path
    assert_select "head meta[name=robots][content='noindex, nofollow']", count: 1

    # 화면의 meta 는 글에만 붙는다. 머리말은 앱이 내는 모든 응답에 붙는다 —
    # 로봇에게 하는 말, 내보낸 파일, 글이 아닌 것까지.
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]

    get robots_path
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]
  end

  test "한 줄로 푼다 — SEARCHABLE=true 면 로봇을 들이고 noindex 를 걷는다" do
    with_env("SEARCHABLE", "true") do
      assert SearchGate.open?

      get robots_path
      assert_equal "User-agent: *\nAllow: /\n", response.body

      get new_session_path
      assert_select "head meta[name=robots]", false, "열었는데 noindex 가 남아 있다"
      assert_nil response.headers["X-Robots-Tag"], "열었는데 머리말이 남아 있다"
    end
  end

  test "막는 말은 한 곳에서만 온다 — public 에 robots.txt 를 두지 않는다" do
    assert_not Rails.root.join("public/robots.txt").exist?,
      "public 의 robots.txt 가 설정보다 먼저 응답한다"
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
