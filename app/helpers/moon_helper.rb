# This app is a raft. — 이 앱도 뗏목이다.
#
# 차오르는 달을 먹색 원호로 그린다. 애니메이션 없음, 숫자 없음.
module MoonHelper
  # phase: 0.0(삭) … 1.0(망). 오른쪽에서 차오른다.
  #
  # 「달의 자취」의 달은 날들을 모아 차오르고, 앉음의 달은 그 한 자리에서
  # 조용히 기운다. 같은 도상이 두 방향으로 쓰이며 서로를 설명한다.
  def moon_svg(phase, size: 160, title: t("moon.title"), **path_options)
    r = size / 2.0

    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size,
            class: "moon", role: "img", "aria-label": title) do
      concat tag.title(title)
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none",
                        stroke: "var(--rule)", "stroke-width": 1)
      concat tag.path(d: moon_path_d(phase, size), fill: "var(--ink)", **path_options)
    end
  end

  # 같은 식이 app/javascript/controllers/sitting_controller.js 에도 있다.
  # 앉는 동안 달이 기우는 것은 브라우저가 그리기 때문이다.
  def moon_path_d(phase, size)
    f = phase.to_f.clamp(0.0, 1.0)
    r = size / 2.0
    rx = (r * (1 - 2 * f).abs).round(3)
    sweep = f < 0.5 ? 1 : 0

    "M #{r} 0 A #{r} #{r} 0 0 1 #{r} #{size} A #{rx} #{r} 0 0 #{sweep} #{r} 0 Z"
  end
end
