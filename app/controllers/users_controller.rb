# This app is a raft. — 이 앱도 뗏목이다.
#
# 이메일 외에는 아무것도 묻지 않는다. 시간대는 브라우저에서 추정해 받는다.
class UsersController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_user_path, alert: t("errors.try_later") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(locale: I18n.locale.to_s))
    @user.time_zone = "Asia/Seoul" unless ActiveSupport::TimeZone[@user.time_zone.to_s]

    if @user.save
      start_new_session_for @user
      redirect_to today_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # 검증과 저장 사이에 같은 이메일이 들어온 경우.
    @user.errors.add(:email_address, :taken)
    render :new, status: :unprocessable_entity
  end

  private
    def user_params
      params.expect(user: [ :email_address, :password, :password_confirmation, :time_zone ])
    end
end
