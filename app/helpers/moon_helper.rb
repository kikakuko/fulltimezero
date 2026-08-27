# This app is a raft. — 이 앱도 뗏목이다.
#
# 달은 언제나 차오른다.
#
# 「달의 자취」의 달은 스물여드레에 걸쳐 차오르고, 앉음의 달은 그 한
# 자리에서 차오른다 — 긴 호흡과 짧은 호흡이 같은 방향을 본다.
# 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
#
# 도상은 원 하나와 가리개 하나로 이루어진다. 차오름은 가리개의 가로
# 반지름(rx) 하나만 움직여 만든다 — 그래야 브라우저가 그 사이를 이어
# 붙여 계단 없이 차오를 수 있다.
module MoonHelper
  # phase: 0.0(그믐) … 1.0(보름). 오른쪽에서 차오른다.
  def moon_svg(phase, size: 160, title: t("moon.title"), smile: false, **shade_options)
    r = size / 2.0
    id = "moon-#{@moon_seq = @moon_seq.to_i + 1}"

    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size,
            class: "moon", role: "img", "aria-label": title) do
      concat tag.title(title)
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none",
                        stroke: "var(--rule)", "stroke-width": 1)
      concat moon_shade(id, phase, size, **shade_options)
      concat tag.circle(cx: r, cy: r, r: r, fill: "var(--ink)", mask: "url(##{id})")
      concat moon_smile(size) if smile
    end
  end

  private
    # 오른쪽 반원은 늘 빛의 자리다. 가리개가 반달 이전에는 빛을 덜어내고,
    # 반달 이후에는 왼쪽으로 빛을 넓힌다. 움직이는 것은 rx 뿐이다.
    def moon_shade(id, phase, size, **options)
      f = phase.to_f.clamp(0.0, 1.0)
      r = size / 2.0

      tag.mask(id: id) do
        concat tag.rect(x: r, y: 0, width: r, height: size, fill: "white")
        concat tag.ellipse(cx: r, cy: r, rx: (r * (1 - 2 * f).abs).round(2), ry: r,
                           fill: f < 0.5 ? "black" : "white", **options)
      end
    end

    # 달의 미소. 감은 눈 같은 선 두 획, 그 이상은 그리지 않는다.
    # 드물게만 떠오르고 이내 사라진다 — 온기는 빈도가 낮을수록 진하다.
    def moon_smile(size)
      r = size / 2.0
      span = size * 0.12
      lift = size * 0.05

      tag.g(class: "smile", "aria-hidden": true, fill: "none",
            stroke: "var(--paper)", "stroke-width": (size * 0.014).round(2),
            "stroke-linecap": "round") do
        [ -1, 1 ].each do |side|
          cx = r + side * size * 0.19
          concat tag.path(d: "M #{(cx - span / 2).round(2)} #{(r - lift).round(2)} " \
                             "q #{(span / 2).round(2)} #{-lift} #{span.round(2)} 0")
        end
      end
    end
end
