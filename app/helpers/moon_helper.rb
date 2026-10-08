# This app is a raft. — 이 앱도 뗏목이다.
#
# 달은 비워 그린다. 쉰 만큼 먹이 빠진다 — 코끼리와 같은 말.
# 밤은 먹 바른 종이, 달은 먹을 비운 자리 — 밤에도 비는 쪽이 종이다.
#
# 달은 언제나 차오르는 달의 모양이다 — 비는 쪽이 오른쪽이다.
#
# 마당의 달은 스물여드레 가운데 쉬었거나 앉은 날만큼 비어 있다. 날이 창 밖으로
# 밀려나 덜 차게 되어도 **기우는 달의 모양을 쓰지 않는다**(§2) — 오른쪽이
# 비는 그믐과 초승으로 돌아갈 뿐이다. 시간의 소진이 아니라 고요의 익어감이
# 이 앱의 문법이다.
#
# 그림은 가는 먹선 원이 몸체를 잡고, 어두운 쪽을 옅은 먹으로 채운다. 밝은 쪽은
# 한지 그대로 — 채우지 않는다. 보름은 먹선 원 하나에 속이 빈 일원상, 그믐은
# 옅은 먹으로 찬 원이다. 차오름은 가리개의 가로 반지름(rx) 하나만 움직여
# 만든다 — 그래야 브라우저가 그 사이를 이어 붙여 계단 없이 차오를 수 있다.
module MoonHelper
  # 반달에서 경계가 자를 댄 직선이 되지 않게 — 먹의 결은 아주 조금이라도 휜다.
  LEAST_RX = 1.0

  # phase: 0.0(그믐) … 1.0(보름). 오른쪽에서 차오른다.
  # moonlight: 보름에 닿은 그 순간에만 참이 된다 — 먹선 원 바깥에 옅은 금빛 번짐
  # 한 겹이 핀다. 빈 원은 비워 둔다. 빛무리는 도상에 두지 않는다는 원칙의
  # 예외가 아니라, 밝은 바탕에서 피는 월광 한 겹이다.
  # from: 달이 응답하는 순간 — 「쉬었다」를 누른 그때만 — 어디서 시작하는가. 가리개는 거기
  # 그려지고, 스크립트가 phase 의 자리까지 옮긴다(moon_controller). 경과 시간이 아니라 사건이다.
  def moon_svg(phase, size: 160, title: t("moon.title"), moonlight: false, from: nil, **shade_options)
    r = size / 2.0
    id = "moon-#{@moon_seq = @moon_seq.to_i + 1}"
    filling = !from.nil? && from != phase
    fill_attrs = if filling
      { style: "--moon-rx: #{shade_rx(from, size)}px",
        data: { controller: "moon", moon_rx_value: shade_rx(phase, size), moon_lit_value: phase.to_f >= 0.5, moon_least_value: LEAST_RX } }
    else
      {}
    end

    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size,
            class: class_names("moon", moonlight: moonlight, "moon--filling": filling),
            role: "img", "aria-label": title, **fill_attrs) do
      concat tag.title(title)
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none", stroke: "var(--gilt)", class: "moonglow") if moonlight
      # 종이 — 낮에는 비워 둔다(한지 위라 채울 것이 없다). 밤에는 비는 쪽이 종이가 되어야
      # 하므로 한지로 채우고, 그 위에 어두운 쪽을 밤빛으로 덮는다(CSS 의 .night).
      concat tag.circle(cx: r, cy: r, r: r, fill: "none", class: "body")
      concat moon_shade(id, filling ? from : phase, size, **shade_options)
      # 어두운 쪽 — 옅은 먹(옅기는 CSS 의 --moon-dark). 가리개가 비는 쪽을 열어 둔다.
      concat tag.circle(cx: r, cy: r, r: r, fill: "var(--ink)",
                        mask: "url(##{id})", class: "disc")
      # 응답하는 순간, 먹이 빠지는 경계에 금빛 번짐 한 겹 — 보름의 번짐과 같은 색 · 같은 겹.
      # 가리개와 같은 타원이 같이 옮아가고, 경계가 있는 반쪽만 보인다. 이내 가라앉는다.
      if filling
        concat tag.clipPath(id: "#{id}-edge") { tag.rect(x: from < 0.5 ? r : 0, y: 0, width: r, height: size, class: "edge-clip") }
        concat tag.ellipse(cx: r, cy: r, rx: shade_rx(from, size), ry: r, fill: "none", stroke: "var(--gilt)",
                           class: "edge", "clip-path": "url(##{id}-edge)")
      end
      # 몸체 — 가는 먹선 원.
      concat tag.circle(cx: r, cy: r, r: r - 0.5, fill: "none",
                        stroke: "var(--ink)", "stroke-width": 1, class: "rim")
    end
  end

  private
    # 왼쪽 반원은 늘 어두운 자리다. 가리개가 반달 이전에는 어둠을 오른쪽으로 넓히고,
    # 반달 이후에는 왼쪽에서 어둠을 덜어낸다. 움직이는 것은 rx 뿐이다.
    def moon_shade(id, phase, size, **options)
      f = phase.to_f.clamp(0.0, 1.0)
      r = size / 2.0

      tag.mask(id: id) do
        concat tag.rect(x: 0, y: 0, width: r, height: size, fill: "white")
        concat tag.ellipse(cx: r, cy: r, rx: shade_rx(f, size), ry: r,
                           fill: f < 0.5 ? "white" : "black", **options)
      end
    end

    # 가리개의 가로 반지름 — 반달에서 한 점은 남는다.
    def shade_rx(phase, size)
      [ size / 2.0 * (1 - 2 * phase.to_f.clamp(0.0, 1.0)).abs, LEAST_RX ].max.round(2)
    end
end
