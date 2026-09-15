# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to today_path
    assert cookies[:session_id]
  end

  test "들어올 때 어디서 무엇으로 왔는지 적지 않는다" do
    post session_path, params: { email_address: @user.email_address, password: "password" },
                       headers: { "User-Agent" => "추적하려는 브라우저", "REMOTE_ADDR" => "203.0.113.7" }

    session = @user.sessions.order(:created_at).last
    assert_equal %w[created_at id updated_at user_id], session.attributes.keys.sort
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as @user

    delete session_path

    assert_redirected_to gate_path
    assert_empty cookies[:session_id]
  end

  test "미인증 리다이렉트는 요청한 로케일을 지킨다" do
    get settings_path(locale: :en)
    assert_redirected_to new_session_path(locale: :en)
  end
end
