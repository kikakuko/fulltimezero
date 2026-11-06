# 그림의 결

> This app is a raft. — 이 앱도 뗏목이다.
> 정한 날: 2026-11-05. 바깥 AI 는 그림을 만드는 연장일 뿐이다(STATUS 4절). 참조 그림의 출처는
> `docs/art-sources.md`, 부르는 손은 `script/art/`. 이 문서는 그 연장에 주는 **결**이다.

## 0. 두 결, 경계는 일주문

이 앱의 그림은 결이 둘이다. 사이에 **일주문**이 있다.

| | B — 문 밖, 「속세」 | D — 문 안, 「경내」 |
|---|---|---|
| 결 | 사진 같은 회화 | 한지 위 먹선과 담채. 구도와 빛은 B 를 따른다 |
| 자리 | `/about` 맨 위, 첫 화면의 일주문 앞까지, og 그림, 유튜브 · 인스타, 스토어 그림 | 일주문을 지난 뒤의 모든 화면 — 문 셋의 나머지, 마당, 전각 |
| 넘어갈 때 | 일주문을 지날 때 B 에서 D 로 겹쳐 바뀐다. 문을 지나면 그림 속 절로 들어간다 | — |

**경계 규칙** — B 는 일주문 앞까지만 나온다. 일주문 안쪽 화면에 B 가 나오면 안 된다. 거꾸로 D 는 문 밖에 나오지 않는다.

## 1. B — 사진 같은 회화

결 문장(그림 모델에 주는 영어):

> Style B: a photorealistic painting. Light and materials feel real — early morning light slanting in, mist — with
> only a few brush marks left visible, so it reads as a painting rather than a photograph.

- **산은 반드시 한국 산이다** — 둥근 산세가 겹겹이, 소나무, 능선 사이의 안개. 알프스 같은 바위 봉우리와 전나무 ·
  가문비 숲은 쓰지 않는다. 결 문장 곁에 늘 이 줄을 붙인다:

  > The mountains are Korean: soft rounded ridges layered one behind another, pine trees, and mist between the
  > ridges. No Alpine rock spires, no fir or spruce forests.

- **참조에는 늘 하나 이상** — R03(정선 〈개화사〉, 산의 생김)과 한국 절 사진(장부의 「씀」 가운데 하나). B 시안
  하나만 넣으면 산세가 바깥 산 쪽으로 치우친다(2026-11-05 선방 시험에서 그랬다).
- 위쪽 3분의 1은 하늘 · 안개 · 먼 능선으로 비워 둔다.

## 2. D — 한지 위 먹선과 담채

**결의 기준(2026-11-06 에 고쳤다)** — **재료는 A, 색과 명암은 D 시안.**

**기준 그림: D3c** — `docs/sources/art/gate-d3c.jpg`(2026-11-06, 일주문. D3c 에서 문 뒤 안개 속 뾰족한 침엽수를 둥근 소나무로
고친 것 — `tmp/art/gate-d3c-fixed-1.jpeg`). D 의 그림은 이 한 장과 나란히 놓아 본다. D3a(`docs/sources/art/gate-d3a.jpg`)는
재료와 자리의 참조로만 남는다.

| | 기준 | 무엇을 따르나 |
|---|---|---|
| 재료 | A 계열 — 시안 A(`tmp/art/realism-a-ink-1.jpeg`) · D3a(`docs/sources/art/gate-d3a.jpg`) | 먹선 · 한지 결 · 평평한 담채 면. 사진의 피사계 심도 · 입자 · 재질 표현은 없다 |
| 색과 명암 | D 시안(`tmp/art/realism-d-ink-framed-1.jpeg`) | 소나무는 짙은 초록, 기둥은 붉게, 아침 빛은 따뜻하게, 그늘은 분명하게. **여백(한지의 흰빛)은 하늘에만** |

까닭 — D3a · 천왕문 · 선방 방이 모두 바탕이 희고 색이 씻겼다(2026-11-06). D 시안을 재면 밝기 0.545 · 대비 0.235 ·
흰 바탕(밝기 0.82 이상) 16.8% 인데, D3a 는 0.687 · 0.164 · 26.8%, 천왕문 벽은 0.73–0.76 · 0.13 · 31–40% 였다(재는 법과 값은
`docs/M-landing-design.md` 10절). 이미지 처리로 흰 끝 내림 · 대비 · 채도를 올려 보면 어두워지기만 하고 그늘이 생기지 않는다 —
벽처럼 넓은 평면은 거의 바뀌지 않는다.

결 문장(D3c 를 만든 그대로 — `script/art/two_moods.rb d3c`):

> Style: the materials are those of ink painting on hanji — clear ink outlines, the fibers of the hanji visible
> throughout, color laid in flat areas of wash. No photographic texture at all — no photographic depth of field,
> no photographic grain, no realistic material rendering. But the color and the light are full, not washed out:
> the pine needles are a deep, dark green; the pillars of the gate are clearly red; the tree trunks are dark; the
> morning light is warm; the shadows on the path, under the eaves and among the trees are distinct. The bare white
> of the paper shows only in the sky and the mist — everywhere else the paper is covered with wash. Dancheong is
> muted, not bright. No gold anywhere.

- **참조의 차례와 역할** — 첫째에 D 시안(「색과 명암 — 얼마나 어둡고 따뜻한지, 대비와 그늘, 한지의 흰빛을 어디에
  남기는지」), 둘째에 A 계열(「재료만 — 그 옅고 씻긴 색은 따르지 말 것」), 끝에 자리 그림(D3a 나 B, 「문 · 나무 · 길의
  자리와 크기만」). B 를 결의 참조로 넣으면 B 를 옅게 씻은 회화(D2)가 나온다 — 2026-11-05 에 그랬다.
- **단청은 눌러서, 그러나 씻지 않고** — 청록과 붉은 기둥이 원색은 아니되 또렷하게 선다. 원색이 서면 다시 그린다.
- **아래 땅도 담채** — 흙길 · 이끼 · 낙엽까지. 위만 담채이고 아래가 사진처럼 남으면 D 가 아니다. 땅에는 그늘이 진다.
- **빛줄기도 먹의 번짐으로** — 사진의 피사계 심도 · 입자 · 재질 표현은 쓰지 않는다.
- **선방 방은 조금 옅어도 된다** — 탱화(족자 안의 산수)가 주인공이라 방은 한 걸음 물러선다. 그래도 지금(밝기 0.77 ·
  흰 바탕 41%)보다는 짙게 — D 시안 쪽으로 6할을 목표로 한다.
- **금빛은 없다**(§2) — 그대로다.
- 같은 자리를 B 와 D 로 둘 다 그릴 때(일주문처럼 겹쳐 바뀌는 자리)는 B 를 먼저 그리고, 위의 순서로 D 를 그린다.
  두 그림의 문 기둥 자리를 재어 맞는지 본다(D3a 는 896 폭에서 B 와 4px 안, D3c 는 2px 안). 겹침의 가운데(0.8초)는
  「재료가 바뀐다」로 읽혀야 한다 — 밝기가 바뀌는 것으로 읽히면 D 가 너무 옅다.
- **현판은 비워 둔다** — 그림 연장은 글자를 그리지 않는다. 빈 판의 자리를 재어 두고 앱이 글자를 얹는다
  (`docs/M-landing-design.md` 11절). 그림 속 판은 짙은 나무빛이라 글자는 한지빛(`--paper`)으로 — 금빛은 쓰지 않는다(§2).

## 3. 둘 다

- **코끼리 · 달 · 미륵 · 탑은 그림에 그리지 않는다**(§2). 네 도상은 앱이 따로 그린다 — 코끼리의 흰빛 · 걸음 ·
  뒤척임, 달의 차오름, 미륵의 드러남, 탑의 한 자는 그림 안에 박히는 순간 멈춘다. 그 자리는 비워 둔다(빈 바위,
  빈 하늘, 빈 마당).
- 사람 · 동물 · 글자 · 현판 글씨 · 낙관 · 해 · 현대 물건(표지 · 난간 · 전등 · 차 · 전선) · 틀은 없다. 옛 그림을
  참조로 넣을 때는 그 그림의 제목과 낙관이 따라오지 않게 금지 줄에 늘 둔다.
- 주사와 금빛은 탑의 한 자에만(§2). 그림의 붉은 기둥은 옅게, 금빛 장식은 들이지 않는다.
- 사경실 참조는 「방의 꼴」만, 감지 · 금니의 색은 들이지 않는다(장부).

## 4. 내보낼 곳

웹 · 안드로이드 앱 · iOS 앱으로 낸다(NEXT 11, Hotwire Native — 앱은 같은 화면을 웹뷰로 연다). 그래서 그림은
한 벌이다. 셋이 같은 그림을 같은 주소로 받는다.

- 화면 그림은 지금처럼 390 폭의 두 배(768–780)를 넘지 않는다(`images_test`). 휴대폰의 배율이 세 배여도 이 그림들은
  안개와 담채라 두 배로 충분하다 — 넘겨야 하면 그때 잰다.
- 스토어 그림(앱 아이콘 · 스토어 스크린샷 · 소개 그림)은 문 밖이라 **B** 다. 크기는 그때 각 스토어의 안내로 잰다.
  아이콘은 지금 것(한지 위 먹빛 코끼리, 주사 없음 — `manifest_test`)을 따른다.
- og 그림은 B, 1200×630, 글자 없음, 120,000 바이트 아래(`og_images_test`).

## 5. 무게 — 그림을 들이기 전에

2026-11-05 에 쟀다(코드는 고치지 않았다). AVIF 는 quality 60 · speed 4, WebP 는 지금 파일 그대로. AVIF 는 이미
손실 압축된 WebP 를 다시 누른 것이라, 원본에서 바로 만들면 조금 달라진다.

| | 그림 합계 | 상한 960,000 에서 남는 자리 |
|---|---|---|
| 지금(WebP 792,078 + SVG · 아이콘 160,987) | 953,065 | 6,935 |
| 구름 셋을 1024 폭 WebP 로(NEXT 8) | 898,987 | 61,013 |
| 지금 크기 그대로 모두 AVIF | 504,479 | 455,521 |
| 모두 AVIF + 구름 1024 | 491,506 | 468,494 |

새 그림 하나의 무게(768 폭): B-일주문 WebP 167,680 · AVIF 88,217 / D2-일주문 WebP 234,352 · AVIF 128,308.

- AVIF 로 가면 `images_test` 의 「화면에 쓰는 그림은 WebP」를 바꿔야 한다(결). 브라우저는 Safari 16(iOS 16) ·
  Chrome 85 · Firefox 93 부터 받는다 — 앱의 웹뷰도 같다. 그 아래를 위해 WebP 를 함께 둘지는 그때 정한다.
- D 는 한지 결과 잔 먹선이 많아 B 보다 무겁다(같은 자리에서 1.4배 안팎).
