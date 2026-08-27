# This app is a raft. — 이 앱도 뗏목이다.
#
# 이 앱이 보내는 유일한 메일. 사용자가 스스로 청했을 때만 나간다.
# 알림이 아니라 물음에 대한 답이다(SPIRIT 제4조 주석).
class PasswordsMailer < ApplicationMailer
  gate :password_reset

  def reset(user)
    @user = user
    I18n.with_locale(@user.locale) do
      mail subject: t("passwords.mailer.subject"), to: user.email_address
    end
  end
end
