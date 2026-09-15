# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경 — 하루에 한 자를 쓴다.
#
# 채점도, 인식도, 정확도도 없다. 쓰면 그걸로 한 자다(제3조).
# 화면에 쓴 획이든 종이에 썼다는 한마디든 똑같이 한 자다(§3).
# 하루 한 자를 이미 썼으면 앱은 문을 닫는다 — 오늘 몫은 끝났다(제2조).
class CopyingsController < ApplicationController
  def new
    @written = Current.user.copyings.includes(sutra_char: :phrase).find_by(copied_on: Current.user.today)
    @char = @written&.sutra_char || Current.user.pagoda.next_char
    @again = comes_again(@char) if @char && !@written
  end

  def create
    copying = Current.user.copyings.new(sutra_char: Current.user.pagoda.next_char, glyph_paths: strokes)

    if copying.save || copying.errors.of_kind?(:copied_on, :taken)
      redirect_to new_copying_path
    else
      redirect_to new_copying_path, alert: copying.errors.messages_for(:glyph_paths).first ||
                                           copying.errors.messages_for(:sutra_char).first
    end
  end

  private
    # 종이에 썼다면 획이 없다. 화면에 썼다면 그은 그대로 받는다.
    def strokes
      return if params[:on_paper].present?

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
