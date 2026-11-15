# This app is a raft. — 이 앱도 뗏목이다.
#
# 고른 원본(docs/sources/art/)을 앱의 그림(app/assets/images/)으로 낸다 — AVIF 는 화면에서 뜨는 크기의 두 배,
# WebP 받침은 480 폭(q60, 첫 화면 그림과 같은 결 — docs/M-landing-design.md 8절). 받침은 AVIF 를 못 받는
# 브라우저만 받으므로 줄여서 받침 상한(images_test 800,000) 안에 든다. 비율은 같다.
#
#   python3 script/art/publish.py          → 아홉 장을 다시 낸다(같은 원본이면 같은 결과)
#   python3 script/art/publish.py bell     → 하나만
#
# Pillow 만 쓴다. 바깥을 부르지 않는다.
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "docs/sources/art")
OUT = os.path.join(ROOT, "app/assets/images")
FALLBACK_WIDTH = 480
# 받침의 품질 — 대개 q60. 둘은 받침이 AVIF 보다 무거워 낮춘다(받침 합계 800,000 안에 들게, 2026-11-15 잼).
FALLBACK_QUALITY = {"bell": 45, "myojeok": 50}


def crop_box(im, box):
    return im.crop(box) if box else im


def cover(im, width, height, anchor_left=False):
    """높이와 너비를 다 덮게 키우고 자른다 — 미륵당 바탕(무대 390 × 560 의 두 배). anchor_left 면 가운데가 아니라 왼쪽에 붙여
    자른다 — 미륵당 화면(390 폭)은 틀보다 무대가 넓어 양옆이 잘리는데, 바탕 b 의 당이 왼쪽에 있어 잘렸다(2026-11-15).
    왼쪽에 붙이면 그림이 무대 안에서 오른쪽으로 옮겨진다(뜰 가운데 · 땅선은 가로로 움직여도 그대로)."""
    scale = max(width / im.width, height / im.height)
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    x0, y0 = (0 if anchor_left else (im.width - width) // 2), (im.height - height) // 2
    return im.crop((x0, y0, x0 + width, y0 + height))


# 이름: (원본, 자르기, 화면 두 배의 폭, AVIF 품질, 흑백인가, 정확한 크기)
PICTURES = {
    # 조감도 d 편집본 — 4:3(1200 × 896)에서 위아래를 잘라 3:2(1200 × 800). 768 × 512 는 옛 조감도와 같은 자리.
    # AVIF q35 — 마당 화면의 첫 짐이 늘지 않게(옛 조감도 38,261 보다 가볍다). q30 과 견줘 기와가 무르지 않는 끝.
    "compound": ("compound-d.jpg", (0, 48, 1200, 848), 768, 35, False, None),
    # 미륵당 바탕 b — 높이를 1120 에 맞추고 가운데 780 을 자른다(M-art-renewal 9절에서 잰 그대로).
    "mireukdang": ("mireukdang-b.jpg", None, 780, 50, False, (780, 1120)),
    "myojeok": ("myojeok.jpg", None, 768, 50, False, None),
    "yegyeong": ("yegyeong.jpg", None, 768, 50, False, None),
    "sagyeong": ("sagyeong.jpg", None, 768, 50, False, None),
    "janggyeong": ("janggyeong.jpg", None, 768, 50, False, None),
    # 범종각 — bells/show 의 자리는 폭 260 까지라 두 배인 520.
    "bell": ("beomjong.jpg", None, 520, 50, False, None),
    # 장경각의 지권인 판 — R57 의 가슴과 두 손, 흑백 그대로.
    "jigwon_plate": ("jigwon-plate.jpg", None, 768, 55, True, None),
    # 곁에 작게 — 『증보 불상도휘』의 지권인, 원본 크기(265 × 235) 그대로. 키우지 않는다.
    "jigwon_butsuzo": ("jigwon-butsuzo.jpg", None, None, 60, False, None),
}


def publish(name):
    source, box, width, quality, gray, exact = PICTURES[name]
    im = crop_box(Image.open(os.path.join(SRC, source)).convert("RGB"), box)
    if gray:
        im = im.convert("L").convert("RGB")
    if exact:
        main = cover(im, *exact, anchor_left=(name == "mireukdang"))
    elif width:
        main = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    else:
        main = im
    main.save(os.path.join(OUT, f"{name}.avif"), "AVIF", quality=quality)
    fallback = main if main.width <= FALLBACK_WIDTH else main.resize(
        (FALLBACK_WIDTH, round(main.height * FALLBACK_WIDTH / main.width)), Image.LANCZOS)
    fallback.save(os.path.join(OUT, f"{name}.webp"), "WEBP", quality=FALLBACK_QUALITY.get(name, 60))
    sizes = [os.path.getsize(os.path.join(OUT, f"{name}.{ext}")) for ext in ("avif", "webp")]
    print(f"{name}: {main.width}×{main.height} AVIF {sizes[0]:,} · 받침 {fallback.width}×{fallback.height} WebP {sizes[1]:,}")


if __name__ == "__main__":
    for name in sys.argv[1:] or PICTURES:
        publish(name)
