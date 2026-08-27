# M1 설계 — 계정 · 쉼 기록 · 달 도상 · 기본 레이아웃(ko/en)

> This app is a raft. — 이 앱도 뗏목이다.
> 근거: [SPIRIT.md](../SPIRIT.md)

## 1. 범위

포함: SPIRIT.md, 계정(가입·로그인·로그아웃), 쉼 기록, 차오르는 달 도상,
ko/en 레이아웃, 하루 몫 종료 화면, 개인정보 페이지 스텁.

제외(다음 마일스톤): 명상 타이머·종성(M2), 침묵 게이트 실동작(M2),
빈 일정 스케줄러(M3), 一字一心(M4), 화두·내보내기·PWA 마감(M5).
단, 알림은 M1에서 **하나도 보내지 않는다** — 게이트가 없으므로 침묵이 기본값.

## 2. 기술 결정

| 항목 | 결정 | 이유 |
|---|---|---|
| 인증 | Rails 8 내장 `bin/rails generate authentication` + bcrypt | devise 불필요. 이메일+비밀번호만 = 최소 수집 |
| DB | SQLite (스캐폴드 그대로) | 단일 서버, 사용자 소유 데이터, 백업 단순 |
| JS | importmap + Stimulus (스캐폴드 그대로) | 달 도상은 서버 렌더 SVG. JS 최소 |
| CSS | Tailwind + 소수의 토큰 | 색·활자는 CSS 변수로 고정 |
| i18n | 경로 스코프 `/:locale` (ko/en), 기본 ko | 국제 웹앱·공유 링크·SEO |
| 시간대 | 사용자별 `time_zone` 컬럼 | "오늘"의 경계가 사용자마다 다르다 |
| 분석 | 없음 | 제6조 |

## 3. 데이터 모델

```
User
  email_address:string  (unique, 소문자 정규화)   ← 유일한 개인정보
  password_digest:string
  locale:string         (ko|en, 기본 ko)
  time_zone:string      (기본 "Asia/Seoul", 가입 시 브라우저에서 추정)
  created_at

Session                 ← Rails 8 인증 생성기 산출물
  user, ip_address, user_agent, created_at

Rest                    ← 쉼 한 건
  user
  rested_on:date        ← 사용자 시간대 기준 날짜. 하루 여러 번 허용
  duration:string       ← 5종 enum. 분으로 환산하지 않는다
  texture:string        ← 5종 enum, nil 허용(건너뛸 수 있다)
  note:text             ← nil 허용, 200자 제한
  created_at
  index [user_id, rested_on]
```

**duration — 쉼의 길이 (분을 저장하지 않는다)**

| 값 | ko | en |
|---|---|---|
| one_breath | 한 호흡 | one breath |
| a_moment | 잠깐 | a moment |
| a_while | 한동안 | a while |
| a_long_while | 오래 | a long while |
| time_fell_away | 시간을 잊었다 | time fell away |

`time_fell_away`는 거절 선택지가 아니라 가장 깊은 쉼의 자기보고다.
목록 마지막에 두되 다른 항목과 같은 크기·같은 색·같은 여백으로 둔다.

**texture — 쉼의 결 (선택 사항)**

| 값 | ko | en |
|---|---|---|
| lay_down | 몸을 뉘었다 | lay down |
| walked | 걸었다 | walked |
| sat_still | 고요히 앉았다 | sat still |
| did_nothing | 아무것도 하지 않았다 | did nothing |
| other | 그 밖 | something else |

**절대 규칙**: 달 계산과 화면 어디에서도 결 사이에 위계를 두지 않는다.
모든 결은 동등하게 하루 1로 센다. 길이도 마찬가지다.

판정 금지(제3조)를 지키기 위해 `Rest`에는 **기분·점수·품질·분 컬럼이 없다.**
`test/models/rest_test.rb` 가 컬럼 목록을 통째로 못박아 검사한다.

## 4. 달 도상 — 차오르는 규칙

```
phase = (최근 28일 중 쉼이 기록된 날의 수) / 28    → 0.0 … 1.0
```

- 28일 이동 창(rolling window). 삭(0) → 망(1). 「달의 자취」 격자도 같은 창을 쓴다.
- **연속기록이 아니다.** 하루 빠뜨려도 "끊겼다"는 개념이 없고,
  창에서 밀려나며 조용히 이지러질 뿐이다(제6조).
- 하루에 여러 번 기록해도 그 날은 1로 센다 — 많이 쉬라고 몰지 않는다.
- 카피는 달을 설명하지 않는다. 숫자·퍼센트·"n일째"를 화면에 쓰지 않는다.

SVG 구현: 지름 D의 먹색 원 + 배경색 타원 마스크.
`rx = (D/2) * |1 - 2·phase|`, phase<0.5면 오른쪽에서 차오르고(초승),
>0.5면 왼쪽 그림자가 줄어든다. 애니메이션 없음. `<title>`에 접근성 텍스트.

## 5. 화면

### (1) 문 — `/ko` (미로그인)

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                 ●                   │   달 하나 (phase=0.5 고정)
│                                     │
│        쉼은 배우는 것이 아니라        │   명조, 24px
│           되찾는 것이다.             │
│                                     │
│            들어가기                  │   밑줄 링크 하나. 버튼 아님
│                                     │
│                            ko | en  │   우하단, 작게
└─────────────────────────────────────┘
```

### (2) 가입 · 로그인 — `/ko/sign_up`, `/ko/session/new`

```
┌─────────────────────────────────────┐
│  시작하기                            │
│                                     │
│  이메일     [                    ]  │
│  비밀번호   [                    ]  │
│                                     │
│  이메일 외에는 아무것도 묻지 않는다.   │   ← 회색 소문자 한 줄
│                                     │
│  [ 시작 ]        이미 계정이 있다면   │
└─────────────────────────────────────┘
```

시간대는 hidden field로 브라우저에서 추정해 넣는다(묻지 않는다).

### (3) 오늘 — `/ko/today` (로그인 후 root)

```
┌─────────────────────────────────────┐
│  fulltimezero            달의 자취 · │   최소 헤더
│                                     │
│                                     │
│               ◐                     │   차오르는 달, 지름 160
│                                     │
│           오늘 쉬었는가.              │   명조
│                                     │
│         [ 쉬었다 ]                   │   유일한 행동
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### (4) 기록 — `/ko/rests/new` (모달 아님, 별도 화면)

```
┌─────────────────────────────────────┐
│  얼마나 쉬었는가                      │
│    ○ 한 호흡                         │
│    ○ 잠깐                            │
│    ○ 한동안                          │
│    ○ 오래                            │
│    ○ 시간을 잊었다                    │   ← 강조하지 않는다. 같은 무게
│                                     │
│  쉼의 결                             │
│    ○ 몸을 뉘었다                      │
│    ○ 걸었다                          │
│    ○ 고요히 앉았다                    │
│    ○ 아무것도 하지 않았다              │
│    ○ 그 밖                           │
│  고르지 않아도 된다.                   │
│                                     │
│  [ 기록 ]                            │
└─────────────────────────────────────┘
```

분은 저장하지도, 환산하지도, 보이지도 않는다.

### (5) 오늘 몫 끝 — 기록 직후

```
┌─────────────────────────────────────┐
│                                     │
│               ◑                     │   조금 더 찬 달
│                                     │
│        기록되었다. 달이 조금 찼다.     │
│                                     │
│        오늘 몫은 끝났다. 이제 쉬어라.  │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

이 화면에는 링크가 없다. 헤더도 감춘다. 닫는 것 말고 할 일이 없다.
(같은 날 다시 `/today`에 오면 달과 이 문장만 보이고 [쉬었다]는 감춘다.
"더 기록하기"는 작은 회색 글씨로 아래에 두되 권하지 않는다.)

### (6) 달의 자취 — `/ko/moon`

```
┌─────────────────────────────────────┐
│  달의 자취                           │
│                                     │
│  ·  ·  ●  ·  ●  ●  ·                │   28칸. 기록된 날만 먹점
│  ●  ·  ·  ●  ●  ·  ●                │   숫자·요일·합계 없음
│  ·  ●  ●  ·  ·  ●  ·                │
│  ●  ●  ·  ●  ·  ●  ●                │   마지막 칸이 오늘
│                                     │
│  지난 스물여드레.                     │
└─────────────────────────────────────┘
```

달과 자취는 같은 28일 창을 본다. 미래 칸은 두지 않는다.
날짜·요일·합계를 쓰지 않는다 — 숫자를 화면에 두지 않기 위해
문구도 "스물여드레"로 적는다.

### (7) 설정 — `/ko/settings`

언어(ko/en) · 시간대 · 로그아웃 · 계정 삭제 · 내보내기(M5, 비활성 안내) ·
개인정보 처리방침 링크.

## 6. 라우트

```ruby
scope "/:locale", locale: /ko|en/ do
  root "gate#show", as: :gate              # 미로그인
  get  "today"    => "today#show"          # 로그인 root
  resource  :session, only: %i[new create destroy]
  get  "sign_up" => "users#new"            # 가입
  post "sign_up" => "users#create"
  resources :passwords, param: :token      # 사용자가 스스로 청한 복구
  resources :rests,   only: %i[new create]
  get  "moon"     => "moon#show"
  get  "settings" => "settings#show"
  patch "settings"=> "settings#update"
  get  "guide"    => "guide#show"          # M3 「쉼의 안내」 스텁
  get  "privacy"  => "pages#privacy"
end
# 브라우저가 한국어를 선호하면 ko, 그 밖에는 en.
root to: redirect { ... }
```

## 7. 파일 구조 (신규)

```
app/models/{user,session,rest}.rb
app/models/moon_phase.rb           # 값 객체: Rest 집계 → phase
app/controllers/{gate,today,rests,moon,settings,pages}_controller.rb
app/controllers/concerns/{authentication,localization}.rb
app/helpers/moon_helper.rb         # SVG 렌더
app/views/...                      # 위 7화면
app/assets/tailwind/application.css # 색·활자 토큰
config/locales/{ko,en}.yml         # 카피 전량. 하드코딩 금지
test/models/moon_phase_test.rb     # 28일 창 경계·시간대 경계
test/integration/rest_flow_test.rb
db/migrate/*                       # users, sessions, rests
```

## 8. 디자인 토큰

```css
--paper: #F7F2E7;  --ink: #1C1A17;  --ink-soft: #6B655C;  --rule: #E2DACA;
다크: --paper: #14120F;  --ink: #E8E1D2;  --ink-soft: #8A8375;  --rule: #2A2620;
제목: "Nanum Myeongjo", "Songti SC", serif      (자체 호스팅, 오프라인 대비)
본문: system-ui, -apple-system, "Pretendard", sans-serif
본문 최대폭 34rem. 기본 여백 넉넉히. 트랜지션 없음 또는 300ms 이상.
```

## 9. 완료 기준

1. 가입 → 로그인 → 쉬었다 기록 → 달이 찬다 → 오늘 몫 종료 화면.
2. ko/en 두 경로 모두 하드코딩 문자열 0.
3. 서로 다른 시간대 사용자에게 "오늘"의 경계가 각자 맞다(테스트).
4. 28일 창 경계 테스트 통과.
5. 이모지·느낌표·숫자 지표가 화면에 없다.
6. 어떤 알림도, 어떤 제3자 요청도 나가지 않는다.

## 10. 승인 후 반영된 변경

1. `duration` 5종 enum. **분 저장·환산 폐기.**
2. `kind` → `texture`(쉼의 결) 5종, 선택 사항, 위계 없음.
3. 「쉼의 안내」(M3) 라우트 스텁 + 5장 제목. 본문 없음.
   각 장이 이어질 기능: 몸의 쉼 → 쉼 기록 · 앉은 쉼 → 명상 타이머(M2) ·
   온전한 쉼 → 무위의 시간(M2).
   (5장 제목 확정: 「온전한 쉼 — 무위와 선정」 / "Complete rest — doing
   nothing, and stillness". 키는 `guide.chapters.complete_rest`.)
4. 「무위의 시간」은 M2에서 명상 타이머와 함께.
5. 「달의 자취」 격자에서 미래 칸 제거 — 달과 같은 창을 본다.
6. 비밀번호 재설정은 남긴다. 알림이 아니라 사용자가 스스로 청한 복구이며,
   제7조(뗏목)상 자기 기록에서 잠기는 일이 없어야 한다.
   이 앱이 먼저 보내는 메일은 없다.

## 11. 헌법 검증 (자동)

`test/integration/spirit_test.rb` 가 모든 화면을 ko/en 양쪽으로 열어 검사한다.

| 검사 | 내용 |
|---|---|
| 숫자 없음 | 화면 텍스트에 숫자·`%`·"분/minutes"·연속기록 표현 없음 |
| 이모지·느낌표 없음 | 화면 텍스트 전체 |
| 제3자 요청 없음 | 렌더된 HTML에 외부 호스트 URL 0건 |
| 알림 0건 | 기록·조회 중 발송·적재된 메일 0건 |
| 자취 | 스물여드레 칸, 날짜·합계 없음 |
| 인용 출처 | 「쉼의 안내」 인용문이 `docs/SOURCES.md`(CC0 원문만)에 있는지 |

`test/models/rest_test.rb` — 평가성·분 컬럼 부재, 컬럼 목록 고정.
`test/models/moon_phase_test.rb` — 창 경계, 시간대 경계, 결·길이 무가중.
