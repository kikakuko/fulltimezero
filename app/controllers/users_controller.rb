# This app is a raft. — 이 앱도 뗏목이다.
#
# 이메일 외에는 아무것도 묻지 않는다. 시간대는 브라우저에서 추정해 받는다.
class UsersController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, by: :throttle_key,
    with: -> { redirect_to new_user_path, alert: t("errors.try_later") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(locale: I18n.locale.to_s))
    @user.time_zone = "Asia/Seoul" unless ActiveSupport::TimeZone[@user.time_zone.to_s]

    if @user.save
      receive_threshold(@user)
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
    # 문 셋을 지나며 세션이 들고 있던 것을 계정으로 옮긴다. 둘째 문의 한 줄과,
    # 문을 지났다는 사실. 옮기고 나면 세션에서 지운다.
    def receive_threshold(user)
      user.update!(what_moves: session.delete(:what_moves)) if session[:what_moves].present?
      user.update!(onboarded_at: Time.current) if session.delete(:threshold_passed)
    end

    def user_params
      params.expect(user: [ :email_address, :password, :password_confirmation, :time_zone ])
    end
end
