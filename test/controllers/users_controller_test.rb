# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_user_path
    assert_response :success
  end

  # 계정이 있으면 이 화면이 곧 들어가는 문이다. 비밀번호가 맞으면 들어가고,
  # 틀리면 한 줄로 말하고 폼으로 돌아온다.
  test "있는 이메일과 맞는 비밀번호면 그 자리에서 들어간다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: { email_address: users(:one).email_address, password: "password", time_zone: "Asia/Seoul" } }
    end

    assert_redirected_to today_path
    assert cookies[:session_id].present?
  end

  test "있는 이메일인데 비밀번호가 다르면 폼으로 돌아온다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: { email_address: users(:one).email_address, password: "wrong", time_zone: "Asia/Seoul" } }
    end

    assert_response :unprocessable_entity
    assert_match I18n.t("errors.sign_in_failed"), response.body
    assert_nil cookies[:session_id].presence
  end

  test "비밀번호 확인 칸이 없다 — 이메일과 비밀번호뿐이다" do
    get new_user_path

    assert_select "input[type=password]", count: 1
    assert_select "input[name='user[password_confirmation]']", false
  end

  test "대소문자와 앞뒤 공백만 다른 이메일도 같은 이메일로 본다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "  #{users(:one).email_address.upcase}  ",
        password: "a good long password",
        time_zone: "Asia/Seoul"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "알 수 없는 시간대는 서버 기본값으로 갈음한다" do
    post users_path, params: { user: {
      email_address: "nowhere@example.com",
      password: "a good long password",
      time_zone: "Mars/Olympus"
    } }

    assert_redirected_to today_path
    assert_equal "Asia/Seoul", User.find_by(email_address: "nowhere@example.com").time_zone
  end
end
