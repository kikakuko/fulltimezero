# This app is a raft. — 이 앱도 뗏목이다.
#
# 지권인(智拳印) — 묘적광전의 빈 연화좌 위, 가슴 높이에 앱이 얹는 손(docs/M-beopdang-design.md 9 · 10절).
# 원본은 장부 R56(철원 도피안사 철조 비로자나불 좌상, 865, 퍼블릭 도메인)의 두 손이다 — 석불(R57)은 선이 흐려 철불로 바꿨다. 꼴: 세운 왼손 검지를
# 오른손이 감싸 쥔다(『한국민족문화대백과』 「비로자나불화」 E0069575). 이 파일은 그 손을 먹선으로 떠서 SVG 로
# 내보내고, 같은 획을 R57 위에 겹쳐 그려 짜임이 맞는지 본다. 표준 라이브러리 + Pillow 만.
#
#   python3 script/art/jigwon.py   → docs/sources/art/jigwon.svg · tmp/art/jigwon-check.jpg
#
# 획은 R56 의 손을 자른 판(tmp/art/refs/R56-hands.jpg, 768 × 892)의 좌표로 적는다. 판의 왼쪽 소매에서 나와 위에서 감싸는
# 주먹이 불상의 오른손, 오른쪽 소매에서 나와 검지를 세운 주먹이 불상의 왼손이다. R57(석불)은 꼴이 같음을 맞춰 보는 데 쓴다.
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# 손 — 또렷하게. (점들, 굵기). 좌표는 R56 의 손을 자른 판(tmp/art/refs/R56-hands.jpg, 768 × 892)의 것.
# 2026-11-12 원본을 R57(석불 — 선이 흐리다)에서 R56(철원 도피안사 철불 — 마디가 또렷하다)으로 바꿨다.
RIGHT_HAND = [  # 오른손: 왼쪽 소매에서 나와 위에서 감싸 쥔 주먹
    ([(70, 172), (130, 150), (190, 108), (250, 48), (300, 16), (380, 6), (424, 26)], 3.4),   # 손등 — 소매에서 마디까지
    ([(424, 26), (444, 46), (436, 58), (446, 86), (438, 108), (446, 136), (436, 160), (440, 186), (420, 214), (392, 232)], 3.4),  # 쥔 손가락의 바깥 — 마디 넷의 굴곡
    ([(300, 58), (360, 52), (432, 62)], 2.2),                                                 # 손가락 사이 — 첫째
    ([(300, 108), (370, 104), (440, 114)], 2.2),                                              # 둘째
    ([(306, 160), (372, 158), (436, 168)], 2.2),                                              # 셋째
    ([(96, 318), (170, 300), (248, 280), (330, 256), (392, 232)], 2.8),                       # 손바닥 아래 가
    ([(56, 160), (52, 230), (60, 320)], 2.0),                                                 # 소매 끝
]
LEFT_HAND = [  # 왼손: 오른쪽 소매에서 나와 검지를 세우고 나머지를 말아 쥔 주먹
    ([(340, 300), (342, 268), (348, 248)], 3.0),                                              # 세운 검지 — 왼쪽 가
    ([(392, 302), (393, 272), (390, 252)], 3.0),                                              # 오른쪽 가(끝은 주먹 안)
    ([(250, 336), (300, 304), (380, 296), (432, 312), (476, 352)], 3.2),                      # 주먹의 위
    ([(262, 372), (304, 346), (382, 350), (424, 382)], 2.4),                                  # 말아 쥔 손가락 — 첫째
    ([(262, 410), (300, 390), (360, 392), (396, 418)], 2.2),                                  # 둘째
    ([(250, 336), (246, 380), (258, 420), (290, 452), (340, 480), (392, 522), (440, 542), (520, 548), (592, 560)], 3.2),  # 주먹의 아래 — 손목까지
    ([(476, 352), (520, 378), (592, 380)], 3.0),                                              # 손등 — 손목까지
    ([(596, 362), (600, 460), (596, 570)], 2.0),                                              # 소매 끝
]
# 둘레의 앉은 몸 — 몇 획만 옅게, 여백으로 풀린다. 둥근 원 · 광배는 없다. 좌표는 같은 판의 것을 넓게 쓴다(R56 의 온몸에서 어림).
BODY = [
    ([(-330, -420), (-160, -520), (60, -560)], 0.32),               # 왼어깨
    ([(560, -560), (790, -500), (950, -380)], 0.32),                # 오른어깨
    ([(-300, -300), (-330, 0), (-250, 300), (-40, 560)], 0.26),     # 왼팔의 가 — 아래로 풀린다
    ([(980, -250), (1020, 60), (930, 360), (740, 600)], 0.26),      # 오른팔의 가
    ([(-520, 980), (-60, 900), (330, 920), (760, 900), (1180, 980)], 0.18),  # 무릎의 선
    ([(230, -700), (320, -660), (410, -700)], 0.22),                # 목 아래 옷깃
]

def catmull(points, steps=18):
    out = []
    pts = [points[0]] + points + [points[-1]]
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(steps):
            t = s / steps
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 +
                                    (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3) for k in range(2)))
    out.append(points[-1])
    return out

def svg_path(points):
    """Catmull-Rom 을 같은 곡선의 3차 베지에로 바꾼다 — 겹쳐 본 획과 SVG 의 획이 같다."""
    pts = [points[0]] + points + [points[-1]]
    d = [f"M{points[0][0]:.1f} {points[0][1]:.1f}"]
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d.append(f"C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f}")
    return " ".join(d)

def write_svg(path):
    # viewBox 는 몸의 획까지 담는다. 손은 가운데, 몸은 옅게(opacity) — 끝은 여백으로.
    x0, y0, w, h = -560, -740, 1780, 1760
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {w} {h}" fill="none" stroke="currentColor" '
             'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">',
             "<!-- 지권인 — 세운 왼손 검지를 오른손이 감싸 쥔다. 원본: 장부 R56(퍼블릭 도메인). 색은 쓰는 쪽이 먹으로 준다(금빛 없음). -->",
             '<g class="jigwon__body">']
    for pts, alpha in BODY:
        lines.append(f'<path d="{svg_path(pts)}" stroke-width="5" opacity="{alpha}"/>')
    lines.append('</g><g class="jigwon__hands">')
    for pts, wdt in RIGHT_HAND + LEFT_HAND:
        lines.append(f'<path d="{svg_path(pts)}" stroke-width="{wdt * 1.6:.1f}"/>')
    lines.append("</g></svg>")
    open(path, "w").write("\n".join(lines) + "\n")

def check(out):
    from PIL import Image, ImageDraw
    im = Image.open(os.path.join(ROOT, "tmp/art/refs/R56-hands.jpg")).convert("RGB")
    over = im.copy()
    d = ImageDraw.Draw(over)
    for pts, wdt in RIGHT_HAND:
        d.line(catmull(pts), fill=(200, 30, 30), width=int(wdt + 1), joint="curve")
    for pts, wdt in LEFT_HAND:
        d.line(catmull(pts), fill=(30, 60, 200), width=int(wdt + 1), joint="curve")
    alone = Image.new("RGB", im.size, (246, 240, 228))
    d2 = ImageDraw.Draw(alone)
    for pts, wdt in RIGHT_HAND + LEFT_HAND:
        d2.line(catmull(pts), fill=(40, 34, 30), width=int(wdt + 1), joint="curve")
    sheet = Image.new("RGB", (im.width * 3 + 40, im.height), (250, 247, 240))
    for k, pic in enumerate([im, over, alone]):
        sheet.paste(pic, (k * (im.width + 20), 0))
    sheet.save(out, quality=90)

if __name__ == "__main__":
    write_svg(os.path.join(ROOT, "docs/sources/art/jigwon.svg"))
    check(os.path.join(ROOT, "tmp/art/jigwon-check.jpg"))
    print("docs/sources/art/jigwon.svg · tmp/art/jigwon-check.jpg")

def composite(base_path, out, cx, cy, hand_width):
    """편집한 그림 위에 같은 획을 얹는다 — 앱이 SVG 를 얹을 자리와 크기를 미리 본다. cx · cy 는 손의 가운데."""
    from PIL import Image, ImageDraw
    base = Image.open(base_path).convert("RGBA")
    k = 4  # 네 배로 그려 줄인다(가장자리를 곱게)
    scale = hand_width / 390 * k  # 손의 너비 — 판에서 x 56–600 가운데 주먹 둘(x 60–450)
    ox, oy = cx * k - 300 * scale, cy * k - 290 * scale  # 손의 가운데는 판의 (300, 290)
    layer = Image.new("RGBA", (base.width * k, base.height * k), (0, 0, 0, 0))
    ink = (44, 36, 30)
    def draw(strokes, alpha_of, width_of):
        for pts, v in strokes:
            line = [(ox + x * scale, oy + y * scale) for x, y in catmull(pts)]
            piece = Image.new("RGBA", layer.size, (0, 0, 0, 0))
            ImageDraw.Draw(piece).line(line, fill=ink + (int(255 * alpha_of(v)),), width=max(1, int(width_of(v) * k)), joint="curve")
            layer.alpha_composite(piece)
    draw(BODY, lambda a: a * 0.9, lambda a: 1.6)
    draw(RIGHT_HAND + LEFT_HAND, lambda w: 0.78, lambda w: 0.5 + w * 0.32)
    layer = layer.resize(base.size, Image.LANCZOS)
    base.alpha_composite(layer)
    base.convert("RGB").save(out, quality=90)
