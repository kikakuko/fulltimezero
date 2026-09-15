# This app is a raft. — 이 앱도 뗏목이다.
class PlansController < ApplicationController
  def create
    plan = Current.user.plans.new(plan_params)
    day = day_path(plan.planned_on || Current.user.today)

    if plan.save
      redirect_to day
    else
      # 빈 줄로 누르면 아무 말 없이 되돌아오던 자리. 한 줄로 까닭을 말한다.
      redirect_to day, alert: plan.errors.messages_for(:what).first || t("days.not_kept")
    end
  end

  def destroy
    plan = Current.user.plans.find(params[:id])
    plan.destroy!

    redirect_to day_path(plan.planned_on)
  end

  private
    def plan_params
      params.expect(plan: [ :planned_on, :what ])
    end
end
