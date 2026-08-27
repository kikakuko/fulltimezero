# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_user_path
    assert_response :success
  end

  test "이미 있는 이메일이면 터지지 않고 폼으로 돌아온다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: users(:one).email_address,
        password: "a good long password",
        password_confirmation: "a good long password",
        time_zone: "Asia/Seoul"
      } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors li",
      text: /#{I18n.t("activerecord.errors.models.user.attributes.email_address.taken")}/
    assert_nil cookies[:session_id].presence
  end

  test "대소문자와 앞뒤 공백만 다른 이메일도 같은 이메일로 본다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "  #{users(:one).email_address.upcase}  ",
        password: "a good long password",
        password_confirmation: "a good long password",
        time_zone: "Asia/Seoul"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "비밀번호 확인이 다르면 폼으로 돌아온다" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "another@example.com",
        password: "a good long password",
        password_confirmation: "a different password",
        time_zone: "Asia/Seoul"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "알 수 없는 시간대는 서버 기본값으로 갈음한다" do
    post users_path, params: { user: {
      email_address: "nowhere@example.com",
      password: "a good long password",
      password_confirmation: "a good long password",
      time_zone: "Mars/Olympus"
    } }

    assert_redirected_to today_path
    assert_equal "Asia/Seoul", User.find_by(email_address: "nowhere@example.com").time_zone
  end
end
