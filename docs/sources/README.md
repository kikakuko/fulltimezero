# 그림의 원본

> This app is a raft. — 이 앱도 뗏목이다.

화면에서 쓰지 않는 그림이다. `app/assets/images/` 에 두면 쓰지 않아도 파이프라인이
통째로 실어 배포까지 따라가므로 여기로 옮겼다. 다시 손볼 일이 있어 지우지는 않는다.

| 파일 | 무엇 |
|---|---|
| `compound_src.png` | 경내 조감도 — 배경을 걷어 내기 전의 원본 |
| `maitreya_src.png` | 미륵 — 잘라 내기 전의 원본 |
| `four_kings.png` | 사천왕 둘로 가르기 전의 한 장 |
| `art/gate-d3a.jpg` | 문 안의 결(D)의 기준 그림 — 일주문(docs/art-style.md) |

## AVIF 를 만든 값(2026-11-05)

`app/assets/images/*.avif` 는 그림 내용을 바꾸지 않고 형식만 바꾼 것이다(docs/M-renewal-design.md). 이 폴더의 PNG 원본에서
Pillow 의 AVIF(speed 4)로 만들었고, 품질은 그림마다 「원본에 대한 충실도(PSNR, 한지빛 위에 얹어 잼)가 지금 WebP 보다
낮지 않은 가장 낮은 값」으로 골랐다. 원본이 WebP 보다 크면(산수) 같은 크기로 줄였다.

| 그림 | 품질 | 바이트(WebP → AVIF) |
|---|---|---|
| `cloud-drift` | 65 | 83,780 → 40,281 |
| `cloud-mist` | 75 | 91,888 → 33,195 |
| `cloud-scroll` | 60 | 90,804 → 29,402 |
| `compound` | 70 | 54,570 → 38,261 — **원본이 아니라 지금 WebP 의 화소에서**(원본 `compound.png` 는 손보기 전의 것이라 지금 그림과 다르다, PSNR 12) |
| `elephant_field` | 80 | 167,102 → 150,309 — 원본 864×1184 를 768×1052 로 |
| `four_king_left` · `_right` | 80 | 17,180 · 16,484 → 16,772 · 16,003 |
| `gates` | 80 | 140,164 → 107,524 |
| `maitreya` | 75 | 42,036 → 31,006 |
| `mireukdang` | 82 | 88,070 → 78,506 |
