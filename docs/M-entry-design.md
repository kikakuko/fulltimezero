# M-entry 설계 — 마당에서 전각으로 들어가는 전환

> This app is a raft. — 이 앱도 뗏목이다.
> 근거: [SPIRIT.md](../SPIRIT.md) · 적은 날: 2026-10-22 · 커밋 `e925957` 기준
> 2026-10-22 에 조사와 설계를 적었고, 같은 날 6절의 다섯을 정해 만들었다. 정한 것과 만든 것은 6절 · 7절에.

## 0. 한 문장

「든다」를 누르면 조감도가 그 전각 쪽으로 1.6초 동안 커지고, 같은 1.6초 동안 전각 그림이
겹쳐 들어온다. 나올 때는 그 길을 거꾸로 걷는다. 움직임을 줄인 화면에서는 바로 바뀐다.

## 1. 지금 구조

### 1.1 마당 → 전각 이동

**Turbo Drive 의 방문(`Turbo.visit`)이다.** 프레임도 아니고 전체 로드도 아니다.

| 차례 | 하는 일 | 자리 |
|---|---|---|
| 1 | 조감도 위 전각 이름(`a.compound__hall`)을 누르면 `compound#open` 이 기본 이동을 막고 **카드**를 아래에서 올린다. 화면은 바뀌지 않는다 | `app/views/today/_compound.html.erb` · `compound_controller.js` |
| 2 | 카드가 열리는 순간, 그 전각의 HTML 을 `fetch` 로 미리 받는다. 앱 전체의 미리 받기는 꺼져 있고(`turbo-prefetch false`), 이것만 누르는 손짓 안에서 받는다 | `compound#prefetch` |
| 3 | 카드의 「든다」를 누르면 `--zoom-x/--zoom-y` 에 전각 중심(백분율)을 넣고 `.compound--zooming` 을 붙인다. 조감도는 `scale(2.6)` 으로 **0.7초** 커지고(ease-in), 한지빛 장막이 0.7초 동안 덮이고, 가운데에 이름이 뜬다 | `application.css` 1400–1423 |
| 4 | 커지기가 끝나고 0.25초 뒤 `Turbo.visit(href)`. 새 화면은 그냥 갈아 끼워진다 — **두 화면이 겹치는 때는 없다** | `compound#enter` · `go` |
| 5 | 움직임을 줄이면 3을 건너뛰고 바로 4. 카드는 그대로 뜬다 | 결 자물쇠 `compound_form_test` |

마당(`courtyard`)은 카드 없이 `#rest` 로 곧장 내려간다. 불이문(`gate`)은 `threshold_path`(첫째 문)로 간다.

**나올 때**: 아래 문(`nav.doors`)의 「마당」을 누르거나 브라우저의 뒤로 가기를 쓴다. 거꾸로 걷는
장면은 **없다.** 뒤로 가기에서는 Turbo 가 떠날 때 담아 둔 스냅숏을 먼저 깐다.
남겨 두는 요소(`data-turbo-permanent`)는 `#gates` 하나뿐이다. 그것을 만지는 컨트롤러는 셋(gates ·
breath · passage)이고, 저마다 `turbo:before-cache` 에서 제가 붙인 것을 걷는다(결 자물쇠 `permanent_test` —
「떠날 때 걷는다」).

### 1.2 `Compound::HALLS` 의 좌표 형식

`app/models/compound.rb`.
`Hall = Data.define(:key, :cx, :cy, :w, :h, :han, :scripture)`

- `cx, cy` 는 누르는 자리의 **가운데**, `w, h` 는 너비·높이다. 넷 다 조감도 그림(`compound.webp`, 768×512)에
  대한 **백분율**이다. `left = cx − w/2`, `top = cy − h/2`.
- 뷰는 `style="left:…%; top:…%; width:…%; height:…%"` 로 그 자리를 놓는다. 「자리와 크기는 한 곳에서 온다」(결 자물쇠)가 지킨다.
- 여덟 자리: 예경당 · 미륵당 · 사경실 · 선방 · 마당 · 장경각 · 범종각 · 불이문. 카드가 있는 것은 마당을 뺀 일곱(`CARD_HALLS`)이다.
- 예경당과 범종각은 조감도에 아직 건물이 없다. 자리만 비워 두었다(NEXT 10(a)).

`cx, cy` 가 그림에 대한 백분율이라는 점이 이번 설계의 열쇠다. 조감도 상자의 `transform-origin`
에 그 값을 그대로 넣으면, 그 전각을 향해 커진다. 지금의 0.7초 확대가 이미 그렇게 한다.

### 1.3 조감도가 그려지는 틀

```
main.sheet
└ div.compound.ink-frame            [data-controller=compound]  먹틀, 화면 양옆 16px
  ├ div.compound__scene             ← 커지는 것(transform)
  │ ├ img.compound__map             compound.webp 768×512, 투명 바탕, 톤은 :root 네 값
  │ ├ span.cloud.cloud--mist        안개띠(cloud-mist.webp)
  │ ├ span.daylight[data-light]     하루의 때 한 겹
  │ ├ span.compound__halo           누른 전각 뒤 후광
  │ └ a.compound__hall--{key} × 8   이름(붓 18px) + 작은 한자(10px)
  ├ div.compound__veil              한지빛 장막
  ├ p.compound__zoom-label          커질 때 가운데 이름
  ├ div.compound__backdrop
  └ div.compound__card.card         카드(role=dialog)
```

전각 화면 쪽 머리는 `compound/_hall_header` 다. 이름(`h1.hall-header__name`)과 한 줄
(`p.hall-header__line`)이 카드의 것과 같은 로케일 키에서 온다.

## 2. 설계 — 전환

### 2.1 움직임

| | 들어갈 때 | 나올 때(마당으로) |
|---|---|---|
| 조감도 | 전각의 `(cx%, cy%)` 를 `transform-origin` 으로, `scale 1 → 2.4`, **1.6초 ease-in-out**, 같은 시간에 불투명도 1 → 0 | `scale 2.4 → 1`, 불투명도 0 → 1. 축은 떠나는 전각의 `(cx, cy)` |
| 전각 그림 | 같은 1.6초 동안 0 → 1(교차 페이드) | 1 → 0 |
| 움직임을 줄이면 | 즉시 | 즉시 |

**시작점**: 이름을 누르면 지금처럼 카드가 뜨고, **「든다」에서 전환이 시작된다**(정했다 — 6절 ①).
카드에는 **이름 · 한 줄 · 「든다」만** 남는다. 카드에 있던 한자는 거두고, 경구와 출전은 그 전각 화면의
글 자리(그림 아래, `compound/_hall_words`)로 옮긴다. 출전의 숫자는 지금처럼 화면 쪽 스크립트가
넣는다(서버 응답에 숫자가 없다 — spirit_form_test). 「경의 말에만 인용 부품」(verse_promise_test)과
「출전은 대조한 표와 글자 그대로」(citation_test)는 자리만 옮겨 그대로 지킨다.

곡선은 `ease-in-out` 이다. 넘침(`--ease-land`)이 아니다. 문 안으로 드는 것은 빛과 사라짐 쪽이라
`motion_test` 의 「넘침은 도착에만」과 부딪히지 않는다. 지금 가운데에 뜨는 이름(`compound__zoom-label`)은
거둔다. 들어간 화면 맨 위에 이름이 서므로(3절) 두 번 말할 까닭이 없다.

### 2.2 구현 후보 둘

조건: 바깥 스크립트 0, 새 젬 0. 둘 다 이 조건을 지킨다. 지금 쓰는 turbo-rails 2.0.23 에는
**Turbo 8.0.23** 이 들어 있고, View Transitions 를 이미 품고 있다.

**(가) Turbo 8 View Transitions.** `<meta name="view-transition" content="same-origin">` 을 마당과
전각 화면에만 둔다. Turbo 는 **떠나는 화면과 오는 화면이 둘 다** 이 meta 를 가질 때만,
`document.startViewTransition` 으로 화면을 갈아 끼운다. 방문 한 번에 한 번만이다.

- 조감도 상자에 `view-transition-name: compound`, 전각 그림에 `view-transition-name: hall`.
  이름이 서로 달라 모양이 이어지지 않는다. 옛 것은 커지며 사라지고, 새 것은 그 자리에 피어난다.
- `::view-transition-old(compound)` 에 `transform-origin: var(--zoom-x) var(--zoom-y)` 와
  `scale(2.4)` 로 가는 keyframes 를 준다. `::view-transition-new(hall)` 은 0 → 1, 둘 다 1.6s ease-in-out.
  옛 조감도 상자의 크기가 그대로 스냅숏의 크기라, 백분율 좌표가 그대로 맞는다.
- 전환의 의사 요소는 `<html>` 에서 상속받는다. 그래서 `compound#enter` 가 `Turbo.visit` 직전에
  `document.documentElement.style` 에 `--zoom-x/--zoom-y` 를 넣는다.
- **나올 때**: Turbo 가 `html[data-turbo-visit-direction="forward|back"]` 을 붙여 준다. 축 값은
  떠나는 전각 화면이 알고 있다. 방 머리(`_hall_header`)에 그 전각의 `cx, cy` 를 데이터로 싣고,
  화면을 떠나 마당으로 가는 방문에서 `<html>` 에 넣는다. 거꾸로 가는 keyframes 는
  `::view-transition-new(compound)`(2.4 → 1)와 `::view-transition-old(hall)`(1 → 0)이다.
  아래 문의 「마당」 링크(forward)와 뒤로 가기(back) 둘 다 같은 장면을 탄다.
- **움직임을 줄이면**: Turbo 가 스스로 끈다(`prefersViewTransitions` 가
  `prefers-reduced-motion: reduce` 이면 거짓이다). 그것에 맡긴다 — CSS 에 따로 두지 않는다.
- **지원하지 않는 브라우저**: Turbo 가 `document.startViewTransition` 이 있는지 보고, 없으면 그냥
  갈아 끼운다. 그 브라우저에서만 지금의 확대(값만 2.4 · 1.6초로)를 방문 앞에 그대로 둔다.
  교차 페이드는 없지만 장면은 끊기지 않는다.
- **축을 넣는 때**: 들어갈 때는 「든다」가, 나올 때는 전각 화면의 `entry` 컨트롤러가, 둘 다
  `turbo:before-render` 에서 `<html>` 에 넣는다 — 옛 화면의 스냅숏은 이미 담긴 뒤이고 새 화면은 아직
  그려지기 전이라, 전환의 의사 요소가 그 값으로 선다. 방향 표시(`data-turbo-visit-direction`)는
  필요 없다 — 조감도는 마당에만, 전각 그림은 전각에만 있어 짝이 저절로 한 방향이다.
- **떠날 때 걷기**: `<html>` 은 Turbo 가 갈아 끼우지 않는다. 그래서 거기 넣은 `--zoom-*` 는 남겨
  두는 요소와 같은 처지가 된다. 값은 **다음 방문이 시작될 때(`turbo:visit`) 걷는다** — 전환이 도는
  동안 걷으면 축이 튄다. 결 자물쇠(`entry_test`): 「`<html>` 의 확대 축 값은 다음 방문에서 걷힌다」.
- **입력**: 전환이 도는 동안 `::view-transition` 의사 요소가 화면을 덮어 손을 받는다 —
  `pointer-events: none` 을 주면 그 밑의 산 화면이 손을 받으니 주지 않는다. 지원하지 않는
  브라우저의 확대 동안에는 `.compound--zooming { pointer-events: none }` 이고, 「든다」는 한 번만 든다.
  결 자물쇠: 「전환 중 두 화면이 동시에 입력을 받지 않는다」.

**(나) `data-turbo-permanent` 틀 안의 CSS 전환.** 조감도와 전각 그림을 한 틀(`#entry`)에 담아
마당과 모든 전각 화면에 같은 id 로 두고, Turbo 가 그 틀을 옮겨 붙이는 동안 클래스를 바꿔 CSS
transition 으로 커지고 옅어지게 한다.

- 모든 브라우저에서 돈다(transform · opacity transition).
- 그러나 전각 화면마다 조감도와 다른 전각의 그림 자리를 DOM 에 지고 다녀야 한다. 마당에서는 그
  틀이 본문 맨 위에, 전각에서는 화면을 덮는 겹이라 자리가 다르다. 갈아 끼우는 순간 틀이 튀지 않으려면
  두 화면 모두에서 고정 겹이어야 하는데, 그러면 마당의 「조감도가 맨 위에 있다」(결)가 흔들린다.
- `permanent_test` 의 「남겨 두는 요소는 `#gates` 하나다」를 풀어야 하고, 만지는 손마다 before-cache
  걷기를 붙여야 한다. 2026-10-08 의 「돌아오니 빛의 길이 다시 돌았다」와 같은 꼴의 사고가 날 자리가
  하나 더 생긴다.

**지원 범위**

| | Chrome / Edge | Safari(macOS · iOS) | Firefox | 앱(Hotwire Native) |
|---|---|---|---|---|
| (가) 같은 문서 View Transitions(`startViewTransition` · `view-transition-name`) | 111 부터 | 18 부터 | 144 부터 | iOS 18 WKWebView 부터 · Android WebView(Chromium) 111 부터 |
| (가) 그 아래 판 | 전환 없이 갈아 끼움 + 방문 앞의 확대 | 같음 | 같음 | 같음 |
| (나) transform · opacity transition | 모든 판 | 모든 판 | 모든 판 | 모든 판 |
| 참고: 문서 사이 전환(`@view-transition`) — 쓰지 않는다 | 126 부터 | 18.2 부터 | 없음 | — |

같은 문서 View Transitions 는 Firefox 144(2025-10)로 세 엔진 모두 갖춘 기준(Baseline newly available)이
되었다. 판 번호는 Chrome 개발자 문서와 web.dev 의 표를 따랐다. 띄우기 전에 MDN 과 실기기로 한 번 더 본다.

### 2.3 고른 것 — (가)

- 두 화면이 **같은 때에 겹치는** 교차 페이드는 (가)만 깔끔하게 한다. (나)도 되지만 틀을 모든 전각에
  지고 다녀야 한다.
- 남겨 두는 요소를 늘리지 않는다. 지난달에 난 사고의 자리를 새로 만들지 않는다.
- 움직임을 줄이면 Turbo 가 스스로 끈다. 지원하지 않는 브라우저에서도 화면은 그대로 바뀐다.
  잃는 것은 장면 하나뿐이고 길은 잃지 않는다.
- 드는 값: 마당과 전각 화면의 meta 한 줄, CSS keyframes 넷, `compound#enter` 의 몇 줄,
  방 머리의 데이터 둘, 나오는 장면을 위한 작은 컨트롤러 하나.

전환이 도는 1.6초 동안 화면은 손을 받지 않는다(View Transitions 의 성질). 지금은 0.7 + 0.25초에
방문 시간이 더해진다. 새 장면은 1.6초 안에 방문 시간이 들어간다. 「든다」에서 그 방이 손에 닿기까지는
거의 같다.

## 3. 전각 화면

### 3.1 모양

```
┌──────────────────────┐
│        선 방          │  ← 이름 하나만. 붓, 그림 위
│                      │
│   (전각 그림 — 전면)    │  ← 화면 높이를 채운다
│                      │
├──────────────────────┤  ← 한 화면 아래
│ 한 줄 · 글 · 손잡이     │
│ 마당 미륵당 선방 사경실  │  ← 아래 문: 들어선 뒤 3초 동안 0.3, 손대면 1
└──────────────────────┘
```

- 이름은 지금 그대로(붓, 지금 자리). 한 줄 · 경구 · 출전은 그림 아래 `compound/_hall_words` 로.
- 그림은 **먹틀과 양옆 16px 을 그대로** 두고 높이만 첫 화면까지 — `--hall-height:
  calc(100svh − --hall-above)`. 그림은 틀을 채운다(가로가 잘린다). 선방의 바위 · 코끼리 · 길의
  안개, 미륵당의 흙 · 미륵 · 금은 그림의 좌표로 서 있으므로, 그림과 같은 비율의 **무대**(`__stage`)를
  틀 가운데 두고 그 안에 그대로 둔다 — 자리 값은 하나도 바뀌지 않는다.
- 머리줄과 아래 문은 **들어선 뒤 3초 뒤에 화면 밖으로 밀려나고**(translate, 옅기가 아니다),
  손길(touchstart · pointerdown) · 스크롤 · 포커스(focusin)에 0.4초로 돌아온다. 돌아온 뒤에는 다시
  나가지 않는다. 숨은 동안은 `inert` 다 — 키보드 사용자가 화면 밖의 것에 갇히지 않는다. 떠날 때는
  되돌린다(`turbo:before-cache`). 스크립트(`hush`)는 전각 화면의 `<body>` 에만 선다.

### 3.2 닿는 자물쇠 — 전부

**침묵(제4조)**

| 자물쇠 | 닿는가 |
|---|---|
| `silence_test` · `silence_gate_test` | **닿지 않는다.** 아래 문이 옅어졌다 돌아오는 것은 소리도 진동도 편지도 아니다. 부르지 않은 것이 오는 일도 없다 |
| `bell_hall_test` 「범종각을 떠나면 소리가 멎는다」 | 닿는다(확인). 전환이 도는 1.6초 동안 범종각의 종소리가 이어진다. 멎는 손이 화면을 떠나는 순간에 걸려 있어 결과는 같아야 한다 — 만든 뒤 실기기로 확인한다 |
| `bell_loading_test` 「범종의 주소는 범종각 밖 어느 화면에도 실리지 않는다」 | 닿는다(조건). 카드를 열 때 전각 **그림**을 미리 받더라도 **소리**는 받지 않는다 |

**카피**

| 자물쇠 | 닿는가 |
|---|---|
| `spirit_form_test` 「카피 어디에도 숫자가 없다」 · 「이모지와 느낌표가 없다」 | 새 카피가 없으므로 닿지 않는다. 한 줄을 옮겨도 키는 그대로다 |
| `compound_form_test` 「방 머리에 전각 이름과 한 줄이 있고, 카드의 것과 같다」 | **닿는다.** 한 줄이 머리에서 아래로 내려가면 `.hall-header__line` 의 자리가 바뀐다. 선택자를 새 자리로 옮긴다(결). 같은 키라는 성질은 그대로 지킨다 |
| `type_test` 「명조는 18px 이상」 · 「붓 셋은 제 글자 자리에만」 | **닿는다.** 그림 위 이름에 붓을 쓰면, 붓이 서는 자리 목록에 `.hall-header__name` 의 새 모양이 들어가야 한다 |
| `spirit_promise_test` 「가르치지 않는다」 · `comparing_test` | 닿지 않는다 |

**결**

| 자물쇠 | 닿는가 |
|---|---|
| `compound_form_test` 「조감도가 커지는 자리는 눌린 전각의 중심이고, 한지빛으로 옅어진다」 | **닿는다.** `scale(2.6)` · `0.7s` · 장막을 박아 두었다. 값을 2.4 · 1.6초로, 장막 대신 교차 페이드로 바꾼다. 「전각의 중심에서 커진다」는 성질은 그대로 둔다 |
| `compound_form_test` 「움직임을 줄이면 카드는 그대로 뜨고 확대만 건너뛴다」 | 지킨다. `return this.go(href)` 의 꼴은 남긴다 |
| `compound_form_test` 「일곱 자리에 카드로 드는 손짓」 | 「든다」에서 시작하면 지킨다. 이름에서 바로 시작하면 **푼다**(정할 것 ①) |
| `compound_form_test` 「먹틀은 가장자리가 있어야 틀이다 — 16px」(compound · maitreya) | **닿는다.** 미륵당 그림을 전면으로 깔면 `.maitreya` 의 `width: calc(100% + 1rem); margin: 0 -0.5rem` 이 바뀐다 |
| `days_form_test` `.maitreya.ink-frame` · `sitting_form_test` `.elephant-field.ink-frame` | **닿는다.** 전면이면 먹틀(테)을 두는지부터 정한다(정할 것 ②) |
| `elephant_flow_test` 「산수 틀이 그림의 비율이다(864/1184)」 · 「코끼리의 길이 맨 위다」 | 비율을 지키면 지킨다. 맨 위는 전면이어도 그대로다 |
| `spirit_form_test` 「네 개의 문이 늘 아래에 있다」 | 구조는 그대로라 지나간다. 다만 0.3 의 3초가 「늘」의 뜻에 맞는지는 사람이 본다. 문은 사라지지 않고 옅어질 뿐이고, 손대면 바로 진해진다 |
| `spirit_form_test` 「몰입 화면은 성역이다 — 문이 없다」 | 닿지 않는다. 전각 화면은 몰입 화면이 아니다 |
| `motion_test` 「넘침은 도착에만」 · 「곡선은 :root 에서」 | 닿는다(조건). 전환과 문의 옅기에 넘침을 쓰지 않는다. 곡선 값은 CSS 에만 둔다 |
| `palette_test` 「색 값은 :root 한 곳에만」 · `NEVER_RED` 의 `.door` | 닿는다(조건). 전환의 바탕은 `var(--paper)`. 문에 주사를 쓰지 않는다 |
| `permanent_test` | (가)는 닿지 않는다. 대신 `<html>` 에 넣는 값의 결 자물쇠를 곁에 하나 더한다. (나)라면 푼다 |
| `cloud_test` 「미륵당에서 구름은 미륵보다 뒤에」 · 「산수화에서 구름은 코끼리보다 뒤에」 | 지킨다. 전면이어도 겹의 차례는 같다 |
| `daylight_test` 「마당과 미륵당에 한 겹이 얹힌다」 | 지킨다. 전환의 스냅숏에 때의 빛이 같이 담긴다 |
| `images_test` 「그림이 화면에서 뜨는 크기보다 크지 않다」 · 합계 960,000 | 지금 그림으로는 닿지 않는다. 새 전면 그림이 오면 **닿는다**(4절) |
| `endless_test`(새 약속) 「저절로 열리는 turbo-frame 이 없다」 | 지킨다. 전각 그림을 `turbo-frame loading=lazy` 로 미루지 않는다 |
| `importmap_test` · `dependency_test` | 지킨다. pin 0, 젬 0 |

**자물쇠는 없지만 걸리는 것**

- **읽힘**: 0.3 의 아래 문은 글자 대비가 4.5:1 아래로 떨어진다. 3초 동안이고 포커스를 받으면 1 이라
  키보드와 스크린리더의 길은 막히지 않는다. 그래도 낮 · 밤 둘 다 실기기로 본다.
- **SPIRIT §2 「여백 — 화면의 대부분은 비어 있어야 한다」**: 그림이 화면을 채우는 것은 글이 화면을
  채우는 것과 다르다. 다만 그림 위에 덧대는 것이 늘면 이 조항에 닿는다. 그림 위에는 이름 하나만 둔다.
- 위의 머리줄(앱 이름 · 설정)을 전각 화면에서 남길지는 정하지 않았다(정할 것 ④).

## 4. 무게

첫 화면(마당)의 실측 무게는 **731,011 바이트**다(압축 전, STATUS 5절, 2026-10-14). 지금 그림으로 잰다.

| 전각 | 전면이 될 그림 | 바이트 |
|---|---|---|
| 선방 | `elephant_field.webp` 768×1052 | 167,102 |
| 미륵당 | `mireukdang.webp` 780×1120 + `maitreya.webp` 534×755 | 130,106 |
| 불이문(첫째 문) | `gates.webp` 780×1688 (+ 사천왕 33,664) | 140,164 |
| 사경실 · 장경각 · 예경당 · 범종각 | 없음 | — |

- **마당에서 전각 그림을 모두 미리 받으면** 731,011 + 297,208(선방 · 미륵당) = **1,028,219 바이트, 41% 늘어난다.**
  불이문까지 더하면 1,168,383(60%). 다만 매일의 문이 뜬 날에는 `gates.webp` 가 이미 받아져 있다.
- **카드를 열 때 그 전각의 그림 하나만 받으면** 첫 화면은 **0 바이트 는다.** 전각에 들면 어차피 받을
  그림을 조금 일찍 받을 뿐이다. 지금도 카드를 열면 그 전각의 HTML 을 받는다(`compound#prefetch`).
  같은 손짓에 그림 한 장을 더한다. 교차 페이드가 빈 그림으로 피지 않으려면 이것이 필요하다.
- 전각 화면 쪽은 그림을 전면으로 깔아도 바이트가 늘지 않는다. 지금 그림이 이미 390 폭의 두 배
  (768–780)라 늘릴 까닭이 없다. 화면 폭이 넓은 기기에서는 가운데 기둥으로 두어 흐려지지 않게 한다.
  선방 화면은 HTML 에 코끼리 그림 둘(54,066 + 39,143)이 인라인으로 실린다 — 그림 파일과 따로 세는 무게다.

**NEXT 8 을 먼저 해야 하는가 — 전환 앞에는 아니다. 새 그림 앞에는 그렇다.**

- NEXT 8 은 「구름 셋을 가로 1024 로 줄여 합계를 850,000 아래로」다. 「전각별 지연 로딩」이라는 항목은
  NEXT 에 없다. 비슷한 것은 STATUS 5절의 「Stimulus 컨트롤러 열아홉을 첫 화면에서 다 받는다 — 전각에
  들어설 때 그 전각의 것만 받으면 50KB 쯤 준다」다. 그림은 Propshaft 가 화면마다 따로 받으므로 이미
  전각별로 받는다. 미룰 것이 없다.
- 전환에는 미리 받는 범위를 **카드를 연 그 전각 하나로** 잡는 것이면 된다. 그러면 첫 화면이 늘지
  않으니 NEXT 8 을 기다리지 않는다.
- 새 전면 그림(5절)은 사정이 다르다. `images_test` 의 합계가 **953,065 / 960,000** 이라 자리가
  **6,935 바이트**뿐이다. 그림 한 장(90–170KB)도 들지 않는다. **5절의 그림을 받기 전에 NEXT 8 을
  먼저 하거나 상한을 다시 정한다.** NEXT 10(e)와 같은 물음이다.
- 컨트롤러를 그 전각의 것만 받게 하는 일(약 50KB, 압축하면 그 셋에 하나)은 이 전환과 따로 갈 수 있다.
  `stimulus-loading` 의 lazy 로 바꾸는 것이라 pin 수가 그대로다.

## 5. 앞으로 필요한 그림

전면 그림이 **없는** 전각은 넷이다.

| 전각 | 지금 화면 | 필요한 것 |
|---|---|---|
| 사경실 | 쓰는 판(SVG)뿐이다. 탑(`pagoda.svg`)은 다른 화면 | 사경실 안 — 경상과 지필묵의 전면 그림 |
| 장경각 | 글뿐(쉼의 안내). 코끼리 아홉은 「자리」 화면의 SVG | 경판 서가의 전면 그림 |
| 예경당 | `bow__figure` 가 빈 자리 | 예경당 안의 전면 그림. 절하는 몸(빈 자리)과는 따로 |
| 범종각 | `bell.webp` 자리만 있다(NEXT 10(b), 520px 범종) | 범종각 전면 그림. 10(b)의 범종 한 장과 겹치지 않게 — 범종을 그 안에 그려 하나로 할지 정한다 |

있는 것: 선방(`elephant_field.webp`), 미륵당(`mireukdang.webp` — NEXT 10(e)에서 바탕과 구름 겹으로
가를 예정), 불이문(`gates.webp`). 넷을 받을 때는 NEXT 10 과 한 번에 묶고, 사양은 지금 것과 같다:
**세로 780 폭 이하 WebP, 담채 · 먹선, 원본은 `docs/sources`.** 받기 전에 4절의 무게 상한부터 정한다.

## 6. 정했다(2026-10-22)

1. **시작점** — 「든다」에서 시작. 카드는 이름 · 한 줄 · 「든다」만. 경구와 출전은 그 전각 화면의
   글 자리(그림 아래)로 옮긴다 — 약속(citation · verse)은 자리만 옮겨 그대로.
2. **전면 그림의 테** — 먹틀과 양옆 16px 유지. 그림 높이만 첫 화면까지.
3. **이름** — 지금 그대로(붓 글꼴, 지금 자리).
4. **머리줄 · 아래 문** — 들어선 뒤 3초 뒤에 화면 밖으로 밀려나고(옅기가 아니다), 손길 · 스크롤 ·
   포커스에 돌아온다. 숨은 동안 inert.
5. **새 그림** — 상한 그대로. 전면은 선방 · 미륵당 둘만. 나머지 넷은 받지 않는다.

## 7. 만든 차례

a. Turbo 8 View Transitions — 마당과 전각 화면에 meta, `view-transition-name` 둘(compound · hall),
   keyframes 넷, 값은 `:root` 의 `--entry-time` 1.6s · `--entry-scale` 2.4. 축은 before-render 에서
   `<html>` 에, 다음 방문에서 걷는다. 지원하지 않는 브라우저는 방문 앞의 확대만(같은 값).
   카드는 이름 · 한 줄 · 「든다」. 경구 · 출전은 `_hall_words` 로. 결 자물쇠 `entry_test` 셋.
b. 선방 · 미륵당 — 그림 높이 `--hall-height`, 무대(`__stage`) 안에 자리 그대로, 글과 손잡이는 한 화면 아래.
c. 머리줄 · 아래 문 — `hush` 컨트롤러, 3초 뒤 translate 로 나가고 손길 · 스크롤 · 포커스에 0.4초로
   돌아온다. 숨은 동안 inert. 결 자물쇠 `hush_test`.
d. 실제 브라우저(390px)로 마당 → 선방 → 마당, 마당 → 미륵당 → 마당. 중간 프레임은 `docs/screens/entry-*`.
   실기기 셋(iOS Safari · 안드로이드 크롬 · 데스크톱 Firefox)은 아직이다 — 띄운 뒤에 본다.

참고: [Chrome 개발자 문서 — View Transition API](https://developer.chrome.com/docs/web-platform/view-transitions) ·
[web.dev — Same-document view transitions are now Baseline newly available](https://web.dev/blog/same-document-view-transitions-are-now-baseline-newly-available)
