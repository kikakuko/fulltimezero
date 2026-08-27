# This app is a raft. — 이 앱도 뗏목이다.
class PlansController < ApplicationController
  def create
    plan = Current.user.plans.new(plan_params)
    plan.save

    redirect_to day_path(plan.planned_on || Current.user.today)
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
