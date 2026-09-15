# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경 — 하루에 한 자를 쓴다.
#
# 채점도, 인식도, 정확도도 없다. 쓰면 그걸로 한 자다(제3조).
# 한 자는 언제나 쓴 글씨다 — 쓰지 않았다는 선언으로 한 자가 되지 않는다.
# 하루 한 자를 이미 썼으면 앱은 문을 닫는다 — 오늘 몫은 끝났다(제2조).
class CopyingsController < ApplicationController
  def new
    @written = Current.user.copyings.includes(sutra_char: :phrase).find_by(copied_on: Current.user.today)
    @char = @written&.sutra_char || Current.user.pagoda.next_char
    @again = comes_again(@char) if @char && !@written
    @vibrate = SilenceGate.allow?(:vibration, user: Current.user)
  end

  # 올리면 방금 쓴 글씨가 탑의 제 자리로 날아가 앉는다. 그 장면에 쓸
  # 탑을 함께 돌려준다 — 쓴 칸만. 빈 칸은 보내지 않는다.
  def create
    copying = Current.user.copyings.new(sutra_char: Current.user.pagoda.next_char, glyph_paths: strokes)
    saved = copying.save

    respond_to do |format|
      format.json do
        if saved
          render json: { scene: PagodaLayout.scene(written, fresh: copying) }, status: :created
        else
          head :unprocessable_entity
        end
      end

      format.html do
        if saved || copying.errors.of_kind?(:copied_on, :taken)
          redirect_to new_copying_path
        else
          redirect_to new_copying_path, alert: copying.errors.messages_for(:glyph_paths).first ||
                                               copying.errors.messages_for(:sutra_char).first
        end
      end
    end
  end

  private
    def written = Current.user.copyings.includes(:sutra_char)

    # 그은 그대로 받는다.
    def strokes
      JSON.parse(params.dig(:copying, :glyph_paths).to_s)
    rescue JSON::ParserError
      :unreadable
    end

    # 이 자가 경에서 다시 오는 구절. 몇 번째인지, 모두 몇 번인지는 세지 않는다.
    def comes_again(char)
      char.sutra.chars.where(glyph: char.glyph).where("pos > ?", char.pos)
          .order(:pos).first&.phrase
    end
end
