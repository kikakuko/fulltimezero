# This app is a raft. — 이 앱도 뗏목이다.
#
# 가입을 받을 것인가 — 운영의 기본은 「받지 않음」이다. 앱이 다 되면 서버에서
# SIGNUPS=true 한 줄로 푼다. 「결」 쪽 자물쇠다 — 열 때가 되면 풀린다.
# 다만 기본이 닫힘인 것과, 닫혔을 때 길까지 없는 것은 손대지 않는다.
# 화면만 숨기면 봇은 길로 들어온다.
require "test_helper"

class SignupGateTest < ActionDispatch::IntegrationTest
  setup { nine_abidings }

  test "운영의 기본은 닫힘이다 — 아무것도 적지 않으면 받지 않는다" do
    as_production { assert SignupGate.closed?, "운영에서 기본이 열림이다" }
  end

  test "여는 말은 하나다 — true 밖의 말로는 열리지 않는다" do
    as_production do
      %w[yes on 1 t enabled TRUE].each do |word|
        with_env("SIGNUPS", word) { assert SignupGate.closed?, "「#{word}」 로 가입이 열렸다" }
      end

      with_env("SIGNUPS", "true") { assert SignupGate.open?, "true 로도 열리지 않는다" }
    end
  end

  test "닫히면 길이 없다 — 가입 · 로그인 · 비밀번호" do
    with_env("SIGNUPS", "false") do
      [ [ :get, "/ko/sign_up" ], [ :post, "/ko/sign_up" ], [ :get, "/ko/session/new" ],
        [ :post, "/ko/session" ], [ :get, "/ko/passwords/new" ], [ :post, "/ko/passwords" ] ].each do |way, path|
        public_send(way, path)
        assert_response :not_found, "#{way} #{path} 의 길이 아직 열려 있다"
      end
    end
  end

  test "닫혀도 나가기는 된다 — 들어온 사람을 가두지 않는다" do
    sign_in_as users(:one)

    with_env("SIGNUPS", "false") do
      delete session_path
      assert_response :redirect

      get today_path
      assert_redirected_to not_yet_path(locale: :ko), "나간 뒤에도 안에 있다"
    end
  end

  test "닫히면 문 셋의 끝과 로그인이 필요한 자리가 한 화면으로 모인다" do
    with_env("SIGNUPS", "false") do
      post threshold_passed_path
      assert_redirected_to not_yet_path

      get today_path
      assert_redirected_to not_yet_path(locale: :ko)

      get not_yet_path
      assert_response :success
      assert_select "h1.title"
    end
  end

  test "열려 있으면 그 화면은 설 자리가 없다 — 가입으로 보낸다" do
    with_env("SIGNUPS", "true") do
      get not_yet_path
      assert_redirected_to new_user_path
    end
  end

  test "닫혀 있는 동안에도 구경하는 길은 열려 있다" do
    with_env("SIGNUPS", "false") do
      [ threshold_path, threshold_naming_path, threshold_breath_path,
        guide_path, abiding_path(pos: 1), privacy_path ].each do |path|
        get path
        assert_response :success, "#{path} 가 닫혔다"
      end

      # 앱의 첫 자리는 계정 없는 사람을 첫째 문으로 보낸다 — 막는 것이 아니다.
      get gate_path
      assert_redirected_to threshold_path
    end
  end

  # 채워야 할 자리({{CPO_NAME}} · {{HOST_NAME}})는 가입을 열 때 선다.
  # 닫혀 있는 동안 공개 화면에 뜨면 깨진 글자로 보인다.
  test "닫혀 있는 동안 공개 화면에 채워야 할 빈 자리가 보이지 않는다" do
    with_env("SIGNUPS", "false") do
      I18n.available_locales.each do |locale|
        [ privacy_path(locale: locale), not_yet_path(locale: locale),
          guide_path(locale: locale), threshold_path(locale: locale) ].each do |path|
          get path
          text = Nokogiri::HTML(response.body).css("body").text

          assert_no_match(/\{\{|\}\}/, text, "#{path} 에 채우지 않은 자리가 보인다")
        end
      end
    end
  end

  test "배포 설정에 기본이 닫힘으로 적혀 있다" do
    deploy = Rails.root.join("config/deploy.yml").read

    assert_match(/SIGNUPS: <%= ENV\.fetch\("SIGNUPS", "false"\) %>/, deploy,
      "배포 설정의 기본이 닫힘이 아니다")
  end

  private
    def as_production
      was = Rails.env
      Rails.env = "production"
      yield
    ensure
      Rails.env = was
    end

    def with_env(name, value)
      was = ENV[name]
      ENV[name] = value
      yield
    ensure
      ENV[name] = was
    end
end
