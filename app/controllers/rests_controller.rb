# This app is a raft. — 이 앱도 뗏목이다.
class RestsController < ApplicationController
  def new
    @rest = Current.user.rests.new
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
