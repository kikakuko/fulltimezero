# This app is a raft. — 이 앱도 뗏목이다.
#
# 이 앱이 보내는 유일한 메일. 사용자가 스스로 청했을 때만 나간다.
class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    I18n.with_locale(@user.locale) do
      mail subject: t("passwords.mailer.subject"), to: user.email_address
    end
  end
end
