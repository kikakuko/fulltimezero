# This app is a raft. — 이 앱도 뗏목이다.
class RestsController < ApplicationController
  # 길이와 결을 적는 자리 — 미륵당의 하루에서 온다. 어느 날의 쉼인지는 그 하루가 준다.
  def new
    # 무위에서 나오며 남기는 기록에는 「시간을 잊었다」가 미리 골라져 있다.
    # 무위는 정의상 재지 않은 시간이므로.
    @rest = Current.user.rests.new(duration: params[:duration].presence_in(Rest::DURATIONS), rested_on: rested_on_param)
  end

  # 둘 중 하나다. 마당의 낙관 — 묻지 않는 틈(rest 가 없다). 미륵당의 하루 — 길이와 결을 적은 쉼.
  def create
    @rest = params.key?(:rest) ? Current.user.rests.new(rest_params) : Current.user.rests.new(without_asking: true)

    if @rest.save
      # 달이 응답한다 — 이 쉼으로 오늘이 처음 고요해졌을 때만, 그 순간 한 번(사건).
      stepped = Current.user.moon_steps_with?(@rest)
      flash[:moon_step] = true if stepped

      if @rest.pause? && !stepped
        # 그 뒤의 틈은 낙관이 찍히는 느낌만 — 달은 움직이지 않고, 마당에 그대로다.
        flash[:stamped] = true
        redirect_to today_path(anchor: "rest")
      else
        redirect_to today_path, notice: t("rests.recorded")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 쉼 기록은 사용자의 것이다(§4). 한 줄씩 지울 수 있어야 한다.
  # 묻는 것은 화면에서 한 번 — 지운 것은 되돌릴 수 없으므로.
  def destroy
    rest = Current.user.rests.find(params[:id])
    rest.destroy!

    redirect_to day_path(rest.rested_on)
  end

  private
    def rest_params
      params.expect(rest: [ :duration, :texture, :note, :rested_on ])
    end

    def rested_on_param
      Date.iso8601(params[:rested_on].to_s)
    rescue Date::Error
      nil
    end
end
