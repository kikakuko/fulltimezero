# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음. 타이머와 무위가 같은 자리를 쓰되, 화면은 서로 다르다 —
# 타이머에는 달이 있고, 무위에는 없다.
class SittingsController < ApplicationController
  before_action :set_sitting, only: %i[show update destroy]

  def new
    @length = SittingLength.new(SittingLength::DEFAULT)
    @bell = SilenceGate.allow?(:bell, user: Current.user)
    @abidings = Abiding.in_order

    # 코끼리 — 앉은 흔적. 흰빛이 바뀐 날의 첫 화면에서만 어제 자리에서 걸어온다.
    @elephant = Elephant.for(Current.user)
    @elephant_moving = @elephant.moved? && session[:elephant_seen_on] != Current.user.today.to_s
    session[:elephant_seen_on] = Current.user.today.to_s
    # 정거장의 이름 — 지명으로만 빌린다. 골라 둔 자리와는 아무 관계가 없다.
    @stations = @abidings.map(&:name)

    # 고른 자리는 지난번 그대로 두되, 안내에서 「이 자리로 앉는다」로 왔으면 그 자리.
    @abiding = Abiding.find_by(pos: params[:abiding]) || Current.user.sittings.where.not(abiding_id: nil)
                                                                   .order(:created_at).last&.abiding
  end

  # 길이와 종성은 그 자리의 설정이므로 저장하지 않고 주소로 지닌다.
  # 고른 자리만 앉음에 남는다 — 비워 둘 수 있고, 무엇도 판정하지 않는다.
  def create
    sitting = Current.user.sittings.create!(mode: "sitting", abiding: Abiding.find_by(pos: params.dig(:sitting, :abiding)))

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

  # 앉음도 사용자의 것이다. 지우면 달도 그만큼 덜 찬다 — 그뿐이다.
  def destroy
    @sitting.destroy!

    redirect_to day_path(@sitting.sat_on)
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
