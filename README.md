# fulltimezero

> This app is a raft. — 이 앱도 뗏목이다.

완전한 쉼으로 가는 온보딩. 쉬었는지 묻고, 앉고, 비우고, 경을 한 자씩
옮겨 쓴다. 참여를 끌어내는 장치는 하나도 없다 — 연속기록도, 알림도, 점수도.
이 저장소의 헌법은 [SPIRIT.md](SPIRIT.md) 이고, 코드가 그것과 부딪히면
코드 쪽을 버린다. 일하는 규칙은 [CLAUDE.md](CLAUDE.md).

## 스택

Rails 8 · SQLite · Hotwire(Turbo · Stimulus) · Tailwind v4 · Propshaft ·
[perfect-freehand](vendor/javascript/perfect-freehand.js)(붓 획, 벤더링) ·
Kamal. **외부 런타임이 없다** — 웹폰트도, 분석 도구도, 제3자 요청도
받지 않는다(SPIRIT 제6조). 소리는 종성 하나이고 브라우저가 합성한다.

## 돌리는 법

```
bin/setup            # 의존성 · DB · 시드
bin/rails db:seed    # 경전 · 아홉 자리(앱의 것) + 개발용 계정 둘
bin/dev              # localhost:3000
bin/review           # 휴대폰으로 보는 임시 https 주소 (혼자 보는 용도)
bin/rails test       # 전 항목. 이것이 통과해야 커밋한다
bin/rubocop
```

개발용 계정 둘 (`db/seeds.rb`):

| 계정 | 상태 |
|---|---|
| `gate@fulltimezero.test` / `fulltimezero` | 문을 아직 지나지 않았다. 온보딩부터 |
| `look@fulltimezero.test` / `fulltimezero` | 두 달을 산 계정. 코끼리는 길 중간, 미륵은 눈까지 |

## 구조 — 자리 넷

화면 아래의 자리 넷이 앱의 전부다. 도상 넷(달 · 미륵 · 코끼리 · 탑)이
하나씩 마주 선다.

| 자리 | 하는 일 | 모델 |
|---|---|---|
| **오늘** | 오늘 쉬었는가. 쉼 기록, 오늘을 비우는 선언, 「쉼의 안내」로 가는 길. 달 | `Rest` `Clearing` `MoonPhase` `Greeting` `Evening` |
| **날들** | 달력 하나 — 일정 · 비워 둔 날 · 고요했던 날. 달력 위에 미륵 | `Plan` `Clearing` `Calendar` `Maitreya` |
| **앉기** | 코끼리의 길, 「앉는다」와 「아무것도 하지 않는다」(같은 무게), 아홉 자리 고르기 | `Sitting` `SittingLength` `Elephant` `Abiding` |
| **사경** | 하루 한 자를 붓으로 쓴다. 글씨는 탑에 앉고, 탑은 언제든 본다 | `Copying` `Sutra` `SutraChar` `SutraPhrase` `Pagoda` `PagodaLayout` |

그 밖에: 처음의 문 셋(`OnboardingController`, 그림 한 장 위의 장막),
「쉼의 안내」 여섯 장(`GuideController`), 침묵 게이트(`SilenceGate`),
내보내기(`Export`). 데이터 파일은 `data/` — 경전과 아홉 자리는 앱의 것이고
값은 파일에서만 온다.

## 자물쇠

`test/` 는 회귀 방지가 아니라 **자물쇠** 다. SPIRIT 의 조항을 코드로 잠가
두어, 누가 언제 무엇을 넣어도 조항과 부딪히면 깨진다. 전부 삼백서른다섯이고
문서가 아니라 검사다.

예를 들어 연속기록을 넣으면 이렇게 깨진다:

- 화면에 「7일째」를 적으면 → `spirit_test` (숫자 0)
- 달력에 「연속」이라는 낱말을 쓰면 → `days_flow_test` (합계 · 연속기록 0)
- `rests` 에 `streak` 컬럼을 더하면 → `rest_test` (컬럼 목록 고정)
- 코끼리를 0 으로 되돌리는 코드를 쓰면 → `elephant_test` (리셋 없음)

주요 자물쇠와 지키는 것:

| 파일 | 지키는 것 |
|---|---|
| `spirit_test` | 숫자 · 이모지 · 느낌표 0, 제3자 요청 0, 인용의 출처, 달의 방향, 자리 넷과 몰입 화면의 성역 |
| `silence_test` | 게이트 밖의 발송 경로 0, 종성 밖의 오디오 0, 진동은 한 파일에서만 |
| `palette_test` | 색은 `:root` 한 곳, 다크 모드 없음, 주사는 오늘 쓴 한 자에만, 탑은 석간주 |
| `languages_test` | 화면의 글은 로케일에만, 언어 목록은 한 곳, 언어마다 금지어 목록 |
| `copy_locks` (도우미) | 언어별 금지어 — 가르침 · 등급 · 명령 · 칭찬 · 나무람 · 셈 |
| `abiding_test` · `elephant_test` · `maitreya_test` | 자리는 판정이 아님, 코끼리와 자리는 잇지 않음, 그리는 쪽은 몇 번인지 모름 |
| `elephant_parts_test` | 코끼리의 무리 아홉과 그 차례, 색은 CSS 만, 축은 data-pivot, 어긋난 짝의 반 주기, 움직임을 줄이면 멈춤, 무리 안에 글 없음 |
| `rest_test` · `sitting_test` | 컬럼 목록 고정 — 점수 · 완주 · 분이 뒷문으로 못 들어옴 |

자물쇠를 고치려면 SPIRIT 개정이 먼저다(§6). 개정은 별도 커밋으로, 이유를
본문에 남긴다.

## 용어

| 말 | 뜻 |
|---|---|
| 구주심 · 아홉 자리 (`Abiding`) | 무착 『성문지』의 아홉 가지 마음의 머묾. 오르는 사다리가 아니라 쉼이 깊어지는 아홉 가지 결. 읽고 고르는 안내이지 사용자의 등급이 아니다 |
| whiteness (`Elephant`) | 코끼리의 흰빛. 스물여드레 가운데 무엇이든 있었던 날의 비율(0 ~ 1). 검은 코끼리가 희어진다. 리셋이 없다 — 쉬지 않으면 서서히 내려갈 뿐 |
| copyings (`Copying`) | 사경 — 하루 한 자를 붓으로 쓴 것. 채점하지 않는다. 쓰면 그걸로 한 자다 |
| clearings (`Clearing`) | 비워 둔 날. 약속이지 목표가 아니다. 지키지 못해도 아무 일 없다. 미륵이 이것으로 올라온다 |
| rests · sittings (`Rest` `Sitting`) | 쉼 기록과 앉음. 길이도 분도 점수도 저장하지 않는다. 그 날 있었다는 사실뿐 |
| 침묵 게이트 (`SilenceGate`) | 바깥으로 나가는 모든 소리와 편지가 지나는 곳. 기준은 하나 — 부르지 않았는데 오는 것만이 알림이고, 알림은 없다 |
| 도상 넷 | 달(오늘) · 미륵(날들) · 코끼리(앉기) · 탑(사경). 넷을 넘지 않고, 도상은 말하지 않는다 |
| 주사(朱砂) | 탑다라니의 붉은 인쇄. 하루에 한 번 — 탑 안의 오늘 쓴 한 자. 탑은 석간주(石間硃) |
| 무위 | 「아무것도 하지 않는다」. 달도 없는 어두운 화면. 끝을 알리지 않는다 |

## docs/

| 문서 | 무엇 |
|---|---|
| [STATUS.md](docs/STATUS.md) | 지금 구조 — 이어서 일하는 사람이 먼저 읽는다 |
| [DEPLOY.md](docs/DEPLOY.md) | 휴대폰으로 보기(터널)와 운영 배포 |
| [SOURCES.md](docs/SOURCES.md) | 인용문의 출전 · 역자 · 라이선스, 데이터의 출처 |
| [baseline-2026-09.md](docs/baseline-2026-09.md) | 개편 전의 기준선. 고치지 않는다 — 비교할 원점이다 |
| [bowing-candidate.md](docs/bowing-candidate.md) | 절하는 자리 — 후보. 만들지 않았다 |
| M1 ~ M4 design | 첫 설계들. 지금 구조와 다른 곳이 있다 — 기록으로 둔다 |

## 그림

피그마: _(링크 자리)_

그림 파일은 `app/assets/images/` — 문 셋(gates.png), 코끼리와 청록 산수,
미륵, 탑(pagoda.svg, 색과 옅기는 CSS 가 준다).
