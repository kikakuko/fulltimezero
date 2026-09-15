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
  # moonlight: 보름에 닿은 그 순간에만 참이 된다.
  # 달 몸체가 한 겹 또렷해진다. 빛무리는 도상에 두지 않는다 — 빛무리는
  # 어두운 바탕의 물리인데, 월광은 언제나 밝은 바탕에서 핀다(형상 원칙 참조).
  def moon_svg(phase, size: 160, title: t("moon.title"), moonlight: false, **shade_options)
    r = size / 2.0
    id = "moon-#{@moon_seq = @moon_seq.to_i + 1}"

    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size,
            class: class_names("moon", moonlight: moonlight),
            role: "img", "aria-label": title) do
      concat tag.title(title)
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none",
                        stroke: "var(--rule)", "stroke-width": 1)
      concat moon_shade(id, phase, size, **shade_options)
      concat tag.circle(cx: r, cy: r, r: r, fill: "var(--ink)",
                        mask: "url(##{id})", class: "disc")
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
end
