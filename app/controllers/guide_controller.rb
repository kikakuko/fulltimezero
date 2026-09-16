# This app is a raft. — 이 앱도 뗏목이다.
#
# 「쉼의 안내」. 한 번에 한 장씩 읽는다.
#
# 장 끝에 다음 장으로 미는 고리를 두지 않는다 — 「하나 더」 유도는
# 이 저장소에 들어올 수 없다(제2조). 읽을 장은 목록에서 고른다.
class GuideController < ApplicationController
  allow_unauthenticated_access

  # 여섯째 장 「아홉 자리」는 글이 로케일이 아니라 data/ 에서 온다.
  CHAPTERS = %w[body walking sitting waking complete_rest abidings].freeze

  def show
    @chapters = CHAPTERS
  end

  def chapter
    @chapter = params[:chapter].presence_in(CHAPTERS)

    return redirect_to guide_path unless @chapter

    if @chapter == "abidings"
      @abidings = Abiding.in_order
      render :abidings
    else
      @body = t("guide.body.#{@chapter}")
    end
  end
end
