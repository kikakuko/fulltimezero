# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음. 타이머와 무위가 같은 자리를 쓰되, 화면은 서로 다르다 —
# 타이머에는 달이 있고, 무위에는 없다.
class SittingsController < ApplicationController
  before_action :set_sitting, only: %i[show update]

  def new
    @length = SittingLength.new(SittingLength::DEFAULT)
    @bell = SilenceGate.allow?(:bell, user: Current.user)
  end

  # 길이와 종성은 그 자리의 설정이므로 저장하지 않고 주소로 지닌다.
  def create
    sitting = Current.user.sittings.create!(mode: "sitting")

    redirect_to sitting_path(sitting, length: length_param, bell: bell_param)
  end

  def nothing
    sitting = Current.user.sittings.create!(mode: "nothing")

    redirect_to sitting_path(sitting, bell: bell_param)
  end

  def show
    # 무위는 한 번만 묻는다. 그 물음이 지나가면 다시 붙잡지 않는다.
    return redirect_to today_path if @sitting.nothing? && @sitting.ended? && !flash[:ask]

    @bell = bell_param && SilenceGate.allow?(:bell, user: Current.user)

    if @sitting.ended?
      @moon = Current.user.moon
      render(@sitting.nothing? ? :leaving : :done)
    elsif @sitting.nothing?
      render :nothing
    else
      @length = SittingLength.new(params[:length])
      @elapsed = @length.seconds_done(@sitting.created_at)
      render :sitting
    end
  end

  def update
    @sitting.finish!

    # 앉음은 마치는 것이고, 무위는 그만두는 것이다.
    if @sitting.nothing?
      redirect_to sitting_path(@sitting), flash: { ask: true }
    else
      redirect_to sitting_path(@sitting)
    end
  end

  private
    def set_sitting
      @sitting = Current.user.sittings.find(params[:id])
    end

    def length_param = SittingLength.new(params.dig(:sitting, :length)).name

    def bell_param
      value = params[:bell] || params.dig(:sitting, :bell)
      value.to_s.in?(%w[1 true])
    end
end
