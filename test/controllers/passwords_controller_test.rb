# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_flash I18n.t("passwords.sent")
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_flash I18n.t("passwords.sent")
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_flash I18n.t("passwords.invalid_link")
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token),
        params: { password: "a new long password", password_confirmation: "a new long password" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_flash I18n.t("passwords.reset")
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_flash I18n.t("passwords.mismatch")
  end

  test "재설정 편지는 사용자의 언어로 쓰인다" do
    mail = PasswordsMailer.reset(users(:two))
    assert_equal I18n.t("passwords.mailer.subject", locale: :en), mail.subject
    assert_includes mail.text_part.body.to_s, I18n.t("passwords.mailer.body", locale: :en)
    assert_includes mail.html_part.body.to_s, I18n.t("passwords.mailer.body", locale: :en)
  end

  private
    def assert_flash(text)
      assert_select ".flash", text: text
    end
end
