# This app is a raft. — 이 앱도 뗏목이다.
#
# 차오르는 달을 먹색 원호로 그린다. 애니메이션 없음, 숫자 없음.
module MoonHelper
  # phase: 0.0(삭) … 1.0(망). 오른쪽에서 차오른다.
  def moon_svg(phase, size: 160, title: t("moon.title"))
    f = phase.to_f.clamp(0.0, 1.0)
    r = size / 2.0
    rx = (r * (1 - 2 * f).abs).round(3)
    sweep = f < 0.5 ? 1 : 0

    path = "M #{r} 0 " \
           "A #{r} #{r} 0 0 1 #{r} #{size} " \
           "A #{rx} #{r} 0 0 #{sweep} #{r} 0 Z"

    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size,
            class: "moon", role: "img", "aria-label": title) do
      concat tag.title(title)
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none",
                        stroke: "var(--rule)", "stroke-width": 1)
      concat tag.path(d: path, fill: "var(--ink)")
    end
  end
end
