# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 부위별 SVG(elephant_parts.svg)를 화면에 그대로 들인다. <img> 로
# 쓰면 부위마다 CSS 가 닿지 않는다. 파일에는 색이 없고, 색 · 걸음 · 흩어짐은
# 모두 CSS 가 --ele(흰빛, 0 ~ 1) 하나로 계산한다. 바깥에서 받아오는 것은 없다.
module ElephantHelper
  PARTS = Rails.root.join("app/assets/images/elephant_parts.svg")

  # scattered: nil 은 모인 채, :now 는 3초에 걸쳐 흩어짐, :already 는 이미 흩어진 뒤.
  # ele 가 없으면 흰빛은 CSS 가 정한다(무위 — 앉은 날과 무관한 하나의 값).
  def elephant_figure(ele: nil, walking: false, scattered: nil, label: nil)
    classes = [ "elephant" ]
    classes << "elephant--walking-legs" if walking
    classes << "elephant--scattering" if scattered == :now
    classes << "elephant--scattered" if scattered == :already

    content_tag :span, elephant_parts_svg(label), class: classes.join(" "), style: (ele && "--ele: #{ele.to_f.round(4)};")
  end

  private
    # 그림은 한 번만 읽는다. 여러 코끼리가 한 화면에 서도(아홉 자리) 부위마다 CSS 가
    # 닿아야 하므로 <use> 로 가리키지 않고 저마다 들인다 — <use> 안에는 CSS 가 닿지 않는다.
    def elephant_parts_source
      return PARTS.read unless Rails.env.production?

      @@elephant_parts_source ||= PARTS.read
    end

    def elephant_parts_svg(label)
      svg = elephant_parts_source.sub(/\A<svg\b[^>]*>/) do
        head = '<svg class="elephant__art" viewBox="0 0 347 243"'
        label ? %(#{head} role="img" aria-label="#{ERB::Util.html_escape(label)}">) : %(#{head} aria-hidden="true">)
      end

      svg.html_safe # rubocop:disable Rails/OutputSafety -- 저장소 안의 그림 파일이고, 이름표만 이스케이프해 넣는다
    end
end
