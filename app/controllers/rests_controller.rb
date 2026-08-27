# This app is a raft. — 이 앱도 뗏목이다.
class RestsController < ApplicationController
  def new
    # 무위에서 나오며 남기는 기록에는 「시간을 잊었다」가 미리 골라져 있다.
    # 무위는 정의상 재지 않은 시간이므로.
    @rest = Current.user.rests.new(duration: params[:duration].presence_in(Rest::DURATIONS))
  end

  def create
    @rest = Current.user.rests.new(rest_params)

    if @rest.save
      redirect_to today_path, notice: t("rests.recorded")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def rest_params
      params.expect(rest: [ :duration, :texture, :note ])
    end
end
