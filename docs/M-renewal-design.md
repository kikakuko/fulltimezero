# M-renewal 설계 — 그림을 새로 들이는 날의 그릇

> This app is a raft. — 이 앱도 뗏목이다.
> 적은 날: 2026-11-05. 같은 날 1–4절대로 만들었다(6절). 그림의 결은 `docs/art-style.md`,
> 참조의 출처는 `docs/art-sources.md`.

## 0. 왜

새 그림(B 문 밖 · D 문 안)을 들이려면 그림 합계 상한(960,000)에 자리가 있어야 한다. 지금은 6,935 바이트가 남는다.
같은 그림을 AVIF 로 주면 합계가 반쯤으로 준다(art-style 5절 — 953,065 → 504,479). 그래서 **받는 쪽은 AVIF 를
먼저, WebP 를 받침으로** 둔다.

## 1. AVIF 먼저, WebP 받침

- **`<img>` 로 서는 그림** — `<picture>` 에 AVIF 를 먼저, WebP 를 받침으로. Rails 의 `picture_tag` 를 쓴다(새 젬 0):

  ```erb
  <%= picture_tag do %>
    <%= tag.source srcset: image_path("compound.avif"), type: "image/avif" %>
    <%= image_tag "compound.webp", class: "compound__map", alt: t("compound.alt"), draggable: false %>
  <% end %>
  ```

  `<img>` 는 받침(WebP) 그대로 두어 클래스 · alt · 자물쇠가 지금처럼 닿는다.
- **CSS 배경으로 서는 그림**(선방 산수 `elephant_field` · 구름 셋) — `image-set()` 에 형식을 적고, 그 앞에 WebP 하나만
  쓴 줄을 받침으로 둔다. 주소는 `:root` 의 변수에 `url()` 로 둔다:

  ```css
  :root { --img-cloud-mist-avif: url("cloud-mist.avif"); --img-cloud-mist-webp: url("cloud-mist.webp"); }
  .cloud--mist {
    background-image: var(--img-cloud-mist-webp);
    background-image: image-set(var(--img-cloud-mist-avif) type("image/avif"), var(--img-cloud-mist-webp) type("image/webp"));
  }
  ```

  까닭: `image-set(url(...))` 로 바로 쓰면 Tailwind 의 CSS 손질(lightningcss)이 받침 줄을 지우고 주소를 `url()` 없는
  문자열로 바꾼다 — propshaft 는 `url()` 안의 주소만 지문 붙은 이름으로 바꾸므로 운영에서 404 가 난다(2026-11-05 에 빌드
  결과로 확인). 변수 안의 값은 손질이 건드리지 않는다.
- **Safari 의 `image-set()` · `type()`(확인함, 2026-11-05)** — MDN 의 호환 자료(browser-compat-data `css.types.image.image-set`)는
  접두 없는 `image-set()` 을 Safari 17 · Chrome 113 · Firefox 89 부터로 적는다. `type()` 은 따로 판이 적혀 있지 않다.
  WebKit 버그 257193 의 답에 따르면 Safari 는 `type()` 을 받지만 후보를 고르는 방식이 다른 브라우저와 달라 **앞에 둔 것을
  먼저 고를 수 있다** — 그래서 AVIF 를 맨 앞에 둔다. Safari 17 아래(iOS 16 포함)는 `image-set()` 줄을 버리고 앞줄의
  WebP 를 쓴다. 실기기(iOS)로는 아직 보지 않았다 — 띄운 뒤 본다.
- **SVG 안의 `<image>`**(선방의 길의 안개 — `cloud-mist` · `cloud-drift`) — `<picture>` 가 없다. 하나만 고른다:
  WebP 로 둔다(가장 넓게 받힌다). 선방 화면의 가장자리 흐름(`.elephant-field .cloud--drift`)도 같은 WebP 를 쓴다 — 여기서만
  AVIF 를 고르면 한 화면이 같은 구름을 두 형식으로 두 번 받는다(선방이 1,026,127 → 1,050,615 로 무거워졌다가, WebP 하나로
  돌려 1,010,409). 선방의 구름 둘까지 AVIF 로 주면 선방은 약 102,000 더 가벼워진다 — 대신 iOS 16 미만에서 길의 안개가
  보이지 않는다. 정할 것.

## 2. iOS 16 미만은 WebP 로 떨어진다

- AVIF 는 Safari 16(iOS 16) · Chrome 85 · Firefox 93 부터 받는다. 앱(Hotwire Native)의 웹뷰도 같다 — iOS 는
  WKWebView, 안드로이드는 시스템 WebView(크로미움).
- iOS 16 미만은 `<picture>` 의 AVIF 를 건너뛰고 WebP 를 받는다. WebP 는 iOS 14 부터라, 그 아래는 이 앱이 받치지
  않는다(지금도 그렇다).
- 같은 그림 두 벌이 저장소에 서지만, 한 화면은 둘 가운데 **하나만** 받는다. 첫 화면 무게는 AVIF 쪽으로 준다.

## 3. `images_test` 를 어떻게 바꾸나 — 받는 쪽 기준

지금 `images_test` 는 「폴더 합계 ≤ 960,000」 · 「화면에 쓰는 그림은 WebP」 · 「폭은 화면에서 뜨는 크기의 두 배 안」을
잠근다. 바꾸면:

| 지금 | 바꾼 뒤 |
|---|---|
| 폴더 합계 ≤ 960,000 | **AVIF 합계**(+ SVG · 아이콘) ≤ 960,000 — 대부분의 사람이 받는 쪽으로 잰다 |
| — | **WebP 받침 합계** ≤ 따로 정한 상한 — 받침이 몰래 불어나지 않게 따로 잰다. 값은 들일 때 잰다 |
| 화면에 쓰는 그림은 WebP | 화면에 쓰는 그림은 **AVIF 와 WebP 가 짝**으로 있다 — 한쪽만 있으면 깨진다. SVG `<image>` 둘은 WebP 만(예외로 이름 붙여 둔다) |
| 폭은 두 배 안 | 그대로 — AVIF · WebP 둘 다 |

- 「성질은 기능, 값은 결」에 따라 이 셋은 결 자물쇠에 둔다. 상한을 바꾸는 커밋은 그림을 들이는 커밋과 따로(CLAUDE.md).
- 첫 화면 무게를 다시 잰다(STATUS 5절 — 실측, `encodedBodySize` 합).

## 4. og 그림 — PNG 를 놓을지

`og_images_test` 는 「`app/assets/images/og/` 의 PNG, 저마다 1200×630, 120,000 바이트 이하」를 잠근다. 새 og(B 결,
2026-11-05)는 사진 같은 회화라 PNG 로는 들지 않는다 — 1200×630 에서 24비트 817,269 · 256색 319,984 · 128색 245,216.
JPEG(q85)로는 115,120, WebP 로는 69,310 이다.

- 정할 것: og 를 **JPEG** 로 받게 자물쇠를 고친다(링크 미리보기는 JPEG 를 가장 넓게 받는다). WebP 를 og 로 받는지는
  카카오톡 · 메신저마다 다를 수 있어 확인하기 전에는 쓰지 않는다.
- 상한 120,000 과 크기 1200×630 은 그대로 둔다.

## 5. 차례(만든 대로)

1. `images_test` · `og_images_test` 를 바꾸는 커밋(결 자물쇠, 까닭을 적는다).
2. 지금 그림을 원본에서 AVIF 로(이미 압축된 WebP 를 다시 누르지 않는다 — 원본은 `docs/sources`).
3. `<picture>` · `image-set()` 으로 바꾸는 커밋.
4. 첫 화면 무게를 다시 재어 STATUS 5절을 고친다.
5. 그다음에 새 그림을 들인다 — 그림마다 따로.

## 6. 했다(2026-11-05)

| | 전 | 후 |
|---|---|---|
| 그림 합계(받는 쪽) — 상한 960,000 | 953,065(남는 자리 6,935) | **702,246(남는 자리 257,754)** |
| WebP 받침 합계 — 상한 800,000 | 792,078 | 792,078(그대로) |
| 첫째 문(손님의 첫 화면) | 763,095 | **730,831** |
| 마당 | 739,924 | **666,007** |
| 선방 | 1,026,127 | 1,010,409 |
| 미륵당 | 814,782 | 733,958 |

첫 화면 무게는 개발 서버 · 390 폭 · 압축 전, `encodedBodySize` 의 합. 네 화면 모두 그림이 AVIF 로 받혔다(선방의 구름 둘은
설계대로 WebP). AVIF 를 만든 값은 `docs/sources/README.md`.
