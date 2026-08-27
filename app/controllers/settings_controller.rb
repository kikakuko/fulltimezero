# This app is a raft. — 이 앱도 뗏목이다.
class SettingsController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(settings_params)
      redirect_to settings_path(locale: @user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end

  # 계정 삭제는 즉시·완전하다.
  def destroy
    user = Current.user
    terminate_session
    user.destroy!
    redirect_to gate_path, status: :see_other
  end

  private
    def settings_params
      params.expect(user: [ :locale, :time_zone ])
    end
end
