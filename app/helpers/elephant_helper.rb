# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 부위별 SVG(elephant_parts.svg)를 화면에 들인다. 그림에는 색값이 없다.
# path 마다 fill="var(--e-fill)" 같은 프레젠테이션 속성만 있고, 색은 바깥 CSS 가
# 흰빛 --ele 하나로 계산해 --e-fill · --e-ink · --e-tusk · --e-fill-far 로 내려 준다.
# 바깥에서 받아오는 것은 없다.
#
# 두 가지로 쓴다.
#   elephant_figure — 인라인. 걷는 코끼리(앉기)와 흩어지는 코끼리(무위)는 무리마다
#     클래스 선택자가 닿아야 하므로 그림을 통째로 들인다.
#   elephant_parts_defs + elephant_use — 서 있는 코끼리 여럿(강원 여섯째 장). 그림을
#     <defs> 에 한 번만 두고 <use> 로 가리킨다. 클래스는 <use> 의 그림자 트리를 넘지
#     못하지만 사용자 지정 속성은 상속되어 넘어간다 — 색이 그렇게 내려간다.
module ElephantHelper
  PARTS = Rails.root.join("app/assets/images/elephant_parts.svg")
  DEFS_ID = "elephant-parts"

  # ele 가 없으면 흰빛은 CSS 가 정한다(무위 — 앉은 날과 무관한 하나의 값).
  def elephant_figure(ele: nil, walking: false, label: nil)
    classes = [ "elephant" ]
    classes << "elephant--walking-legs" if walking

    content_tag :span, elephant_inline_svg(label), class: classes.join(" "), style: elephant_style(ele)
  end

  # 그림 한 벌 — 한 화면에 한 번만 둔다.
  def elephant_parts_defs
    body = elephant_parts_source.sub(/\A<svg\b[^>]*>/, "").delete_suffix("</svg>").strip
    body = body.sub('<g class="elephant__parts">', %(<g class="elephant__parts" id="#{DEFS_ID}">))

    %(<svg class="elephant__defs" width="0" height="0" aria-hidden="true" focusable="false">#{body}</svg>).html_safe # rubocop:disable Rails/OutputSafety -- 저장소 안의 그림 파일이다
  end

  def elephant_use(ele:)
    svg = %(<svg class="elephant__art" viewBox="0 0 347 243" aria-hidden="true"><use href="##{DEFS_ID}"/></svg>).html_safe # rubocop:disable Rails/OutputSafety -- 고정된 틀이다

    content_tag :span, svg, class: "elephant elephant--used", style: elephant_style(ele)
  end

  private
    def elephant_style(ele)
      ele && "--ele: #{ele.to_f.round(4)};"
    end

    # 그림은 운영에서 한 번만 읽는다.
    def elephant_parts_source
      return PARTS.read unless Rails.env.production?

      @@elephant_parts_source ||= PARTS.read
    end

    def elephant_inline_svg(label)
      svg = elephant_parts_source.sub(/\A<svg\b[^>]*>/) do
        head = '<svg class="elephant__art" viewBox="0 0 347 243"'
        label ? %(#{head} role="img" aria-label="#{ERB::Util.html_escape(label)}">) : %(#{head} aria-hidden="true">)
      end

      svg.html_safe # rubocop:disable Rails/OutputSafety -- 저장소 안의 그림 파일이고, 이름표만 이스케이프해 넣는다
    end
end
