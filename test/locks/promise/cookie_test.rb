# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 쿠키는 세션을 잇는 것뿐이다 — 그 밖에 아무것도 심지 않는다.
#
# 이것이 약속 쪽에 있는 까닭: 쿠키가 늘면 「꼭 필요한 쿠키뿐」이라는 근거가
# 무너지고, 그때부터는 동의를 물어야 한다. 묻지 않은 채로 늘리면 사용자는
# 배신당한 것이다. 쿠키 하나가 느는 일은 기능이 아니라 약속을 푸는 일이다.
#
# 심기는 것은 둘이고, 둘 다 세션이다. 하나는 로그인을 잇고(로그인한 뒤에만),
# 하나는 위조 토큰과 한 번 쓰는 알림을 담는다(로그인 전에도). 이름을 외우지
# 않고 「세션을 잇는 것」과 「그 밖」으로 가른다.
class CookieTest < ActionDispatch::IntegrationTest
  include Screens

  setup { heart_sutra }

  # 세션을 잇는 쿠키인가 — 레일즈의 세션 쿠키이거나, 로그인을 잇는 쿠키.
  SESSION_BEARING = /\A(_#{Rails.application.class.module_parent_name.downcase}_session|session_id)\z/

  test "어느 길에서도 세션 밖의 쿠키를 심지 않는다" do
    each_page { |page, locale| assert_only_session_cookies "#{page}(#{locale})" }
  end

  test "들어가고 나가는 길에서도 세션 밖의 쿠키를 심지 않는다" do
    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_only_session_cookies "로그인"

    delete session_path
    assert_only_session_cookies "나가기"
  end

  test "몰입 화면에서도 세션 밖의 쿠키를 심지 않는다" do
    sign_in_as users(:one)

    post sittings_path, params: { sitting: { length: "incense", bell: "1" } }
    assert_only_session_cookies "앉는 중"

    post nothing_path, params: { bell: "1" }
    assert_only_session_cookies "무위"
  end

  # 한 응답이 심는 쿠키는 둘을 넘지 않는다. 늘면 이 수가 먼저 깨진다.
  test "한 응답이 심는 쿠키는 둘을 넘지 않는다" do
    each_page do |page, locale|
      assert_operator set_cookies.size, :<=, 2, "#{page}(#{locale}) 가 쿠키를 셋 이상 심는다"
    end
  end

  # 쿠키의 속살 — 브라우저의 스크립트가 읽지 못하고, 다른 자리에서 온 요청에
  # 실려 가지 않는다. 바깥으로 새지 않는 것이 「꼭 필요한 쿠키」의 조건이다.
  test "심는 쿠키는 스크립트가 읽지 못하고 다른 자리로 실려 가지 않는다" do
    sign_in_as users(:one)
    get today_path

    set_cookies.each do |cookie|
      assert_match(/httponly/i, cookie, "쿠키를 스크립트가 읽는다: #{cookie[/\A[^=]+/]}")
      assert_match(/samesite=lax/i, cookie, "쿠키가 다른 자리로 실려 간다: #{cookie[/\A[^=]+/]}")
    end
  end

  # 쿠키를 심는 코드가 몇 자리인지 — 자리가 늘면 눈에 보이지 않는 쿠키가 생긴다.
  test "쿠키를 심는 코드는 로그인을 잇는 한 자리뿐이다" do
    setters = %w[app lib config].flat_map { |dir| Rails.root.join(dir).glob("**/*.rb") }
      .select { |path| strip_comments(path).match?(/cookies(\.\w+)*(\.permanent)?\[[^\]]+\]\s*=/) }
      .map { |path| path.relative_path_from(Rails.root).to_s }

    assert_equal %w[app/controllers/concerns/authentication.rb], setters,
      "쿠키를 심는 자리가 늘었다. 늘릴 때는 동의 없이 두어도 되는지를 먼저 묻는다."
  end

  # 쿠키에 담기는 것은 신원이지 사람이 아니다 — 이메일도, 이름도, 들어온
  # 자리도 담지 않는다. 담는 값이 세션의 번호 하나임을 코드에서 본다.
  test "쿠키에 담는 것은 세션의 번호뿐이다" do
    laid = strip_comments(Rails.root.join("app/controllers/concerns/authentication.rb"))[/cookies[^\n]*\[[^\]]+\]\s*=\s*\{[^}]*\}/].to_s

    assert_match(/value:\s*session\.id/, laid, "쿠키에 세션의 번호 말고 다른 것을 담는다")
    assert_no_match(/email|name|ip|locale|agent/i, laid, "쿠키에 사람을 적는다")
  end

  private
    def set_cookies = Array(response.headers["Set-Cookie"]).flat_map { |header| header.to_s.split("\n") }.reject(&:empty?)

    def assert_only_session_cookies(where)
      strangers = set_cookies.map { |cookie| cookie[/\A[^=]+/].to_s.strip }.reject { |name| name.match?(SESSION_BEARING) }

      assert_empty strangers, "#{where} 가 세션 밖의 쿠키를 심는다: #{strangers.inspect}"
    end
end
