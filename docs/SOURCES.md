# 콘텐츠 출처와 라이선스

이 앱에 들어오는 인용문·경전 원문·소리는 **CC0(또는 공유 저작물) 원문만**
쓴다. 번역·주석에 저작권이 있는 판본은 쓰지 않는다.

인용문을 하나 들일 때마다 아래에 한 줄을 남긴다:
원문 그대로의 문장 · 출전 · 라이선스 · 확인한 날짜.

`test/locks/promise/spirit_promise_test.rb` 가 「쉼의 안내」의 인용문이 이 목록에
있는지 검사한다.

## 소리

### 종성 — 지금은 합성음

M2의 종성은 브라우저에서 합성한다
(`app/javascript/controllers/bell_controller.js`).
싱잉볼의 비조화 배음(기본음 · 약 2.7배 · 5.4배 · 8.93배)을 겹치고
스물넉 초에 걸쳐 지수 감쇠시킨다. 여운을 뚝 끊지 않는다.
파일이 아니므로 제3자도, 라이선스도, 바깥으로 나가는 요청도 없다.

### 실음원으로 갈아 끼우는 법

재생기는 **파일이 먼저다.** 아래 이름으로 `app/assets/sounds/` 에 넣으면
코드를 고치지 않고 합성음을 대신한다.

```
app/assets/sounds/bell-start.{ogg,mp3,wav,m4a}   시작종
app/assets/sounds/bell-end.{ogg,mp3,wav,m4a}     마침종
```

파일을 하나 들일 때마다 아래에 한 줄을 남긴다:
**원문 제목 · 출처 URL · 라이선스 · 확인한 날짜.**
번역·주석·편곡에 저작권이 있는 판본은 쓰지 않는다.

### 들인 음원 — 범종(성덕대왕신종)

| | |
|---|---|
| 제목 | 성덕대왕신종(에밀레종) 종소리 — 저용량본 |
| 내어 준 곳 | 국립중앙박물관 · 국립경주박물관 |
| 받은 URL | https://www.museum.go.kr/site/main/archive/united/11215 (파일 `/afile/fileDownloadById/12813?siteCode=MUSEUM`) |
| 라이선스 | **공공누리 제3유형 — 출처표시 + 변경금지.** 상업적 이용 가능, 출처를 밝히면 |
| 받은 날 | 2026-10-07 |
| 파일 | 묶음 안의 `bell2.mp3` → `app/assets/sounds/bell-temple.mp3` |
| 손댄 곳 | **없다.** 바이트가 그대로다(1,422,732 바이트, SHA-256 `b092f687…82c`). 이름만 재생기가 찾는 이름으로 두었다 — 소리는 한 자리도 바뀌지 않았다 |
| 재어 본 것 | MP3 · 44.1kHz · 스테레오 · 128kbps · 88.9초. **세 번 친다**(0.4초 · 12.3초 · 26.9초), 마지막 타종 뒤 약 60초가 고르게 사그라들어 88.9초에 완전히 조용해진다. 잘린 데가 없다 |
| 화면의 출처 | 범종각 안, 듣는 자리 아래 한 줄(`bells.source`). 그 한 줄이 「쓰인 것들」(`/credits`)로 가고, 거기에 공공누리 권장 양식 전문이 있다 |
| 개방한 해 | **2016** — 안내문의 작성일(2016-01-22)과 묶음 안 파일의 날짜(2016-01-12)로 확인된다 |
| 녹음한 해 | **알 수 없다.** 어디에도 적혀 있지 않다. 종 자체는 신라 때 것이고 녹음은 그 뒤의 일이다 |
| 표기에서 뺀 말 | 권장 양식의 「작성하여」를 뺐다. 확인된 것은 **개방한 해**이지 작성한 해가 아니다 — 양식을 지키려고 모르는 것을 적지 않는다. 반드시 들어가야 할 셋(기관명 · 저작물명 · 이용조건)은 그대로다 |

**변경금지다.** 자르지도, 형식을 바꾸지도, 다시 누르지도 않는다. 세 번 치는 것을 그대로
받아들였다 — 까닭은 `docs/STATUS.md` 의 범종각 대목에 있다. `sounds_test` 가 바이트
수로 그대로인지 지킨다.

- 앉기의 종(`bell-start` · `bell-end`)은 아직 없다 — 합성음으로 운다

## 인용문

인용은 **CC0 원문 또는 저작권이 소멸한 원문만.** 번역·주석·편곡에
저작권이 있는 판본은 쓰지 않는다. 한국어는 인용하지 않고 자체 산문으로
쓴다 — 현대 한글 번역본에는 저작권이 있다.

### 번역을 들일 수 있는 곳과 없는 곳 (2026-10-08)

**원문은 저작권이 없지만 번역은 있다.** 인용 표(`app/models/citation.rb`)의 `license`
칸이 그 허락을 적는다 — `CC0` · `CC BY-NC`(출처 표시 필요) · `own`(우리가 옮긴 것) 셋
가운데 하나이거나 비어 있다. **남이 옮긴 말이면 비어 있을 수 없다**(약속).

| | |
|---|---|
| **쓸 수 있다** | **SuttaCentral 의 수자또(Bhikkhu Sujato) 영역** — CC0. 역자가 파일 경로에 박힌 것만 |
| **쓸 수 있다, 출처 표시** | **Lotsawa House** — CC BY-NC. 출처를 밝히면 비영리로 쓸 수 있다. 「쓰인 것들」에 저절로 선다 |
| **발췌 금지** | **84000** 의 번역 — CC BY-NC-ND. 변경 금지에 발췌가 걸린다. **한 줄도 따오지 않는다.** 뜻이 필요하면 원문을 보고 우리 말로 쓴다 |
| **확인된 것만** | 한역 경전의 영역 — 공개 라이선스가 확인된 것만. 없으면 우리 말로 |

**원문의 허락 — 확인한 것과 못 한 것**

- **팔리 원문(Mahāsaṅgīti Tipiṭaka Buddhavasse 2500)**: SuttaCentral 은 「옛 글은 그 자체로
  공유 저작물이고, 거기에 거는 어떤 권리 주장도 법적 근거가 없다」는 입장이고, 자체
  제작물(편집 · 번호 · 구두점)은 CC0 로 내놓는다. 즉 **CC0 는 SuttaCentral 의 손질에
  대한 것이고 원문 자체는 공유 저작물**이다. 라이선스 안내 페이지(`suttacentral.net/licensing`)는
  자바스크립트 화면이라 이 세션에서 직접 열지 못했고, 그 페이지를 인용한 자료들로
  확인했다. bilara-data 의 `README.md` 는 「모든 번역은 CC0 여야 한다」고 적는다.
- **한역 원문(CBETA, 대정장)**: 고전 한문 원문은 공유 저작물이다. **CBETA 판본의 편집 ·
  교감 자체에 걸린 라이선스는 이 세션에서 확인하지 못했다** — 우리는 한 문장을 글자
  대조의 증거로만 썼고 판본 전체를 들이지 않았으므로 지금은 걸리지 않는다. 판본을
  들이게 되면 그때 확인한다.

### 주의 — 출처는 사이트가 아니라 역자다

SuttaCentral 에는 **저작권이 살아 있는 역본도 함께 실려 있다**
(비구 보디 등). "SuttaCentral 에서 받았다"는 기록은 근거가 되지 못한다.
받아 온 문장 하나하나가 **수자토(Bhikkhu Sujato) 역본인지**를
파일 경로와 역자 표기로 확인해 아래에 남긴다.
역자 표기가 없는 원문은 **쓰지 않는다.**

### 라이선스 확인 — SuttaCentral / 수자토 역본

| | |
|---|---|
| 확인한 URL | https://github.com/suttacentral/bilara-data — `LICENSE.md` |
| 원문 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/master/LICENSE.md |
| 라이선스 | CC0 1.0 (퍼블릭 도메인 헌정) |
| 확인 일자 | 2026-08-27 |

라이선스 문구 원문 그대로:

> "All translations created in Bilara and supported by SuttaCentral are
> dedicated to the Public Domain by means of the Creative Commons Public
> Domain (CC0) license."

같은 저장소 README 의 보조 문구:

> "Note that all translations supported by SuttaCentral must use CC0 licence."

---

### 전각 카드의 넷 — 한글과 영어는 자체 산문이다

마당의 전각 카드에 서는 네 줄(선방 · 사경실 · 장경각 · 문)은 **원문을 보고 이 앱이
옮긴 자체 산문**이다. 번역본에서 가져오지 않았다 — 위의 규칙 그대로다. 영어도
수자토 역본과 글자가 다르다(「a tamed mind leads to bliss」 ↔ 「A tamed mind brings
happiness」, 「extinguishment, the ultimate happiness」 ↔ 「Nibbāna is the highest
happiness」). 원문 · 판본 · 본 곳 · 옮긴 이 · 대조한 날은 `app/models/citation.rb`
한 곳에 있고 `citation_test` 가 지킨다.

**남의 번역본을 들이게 되면** 그 줄의 `rendered_by` 에 역자와 발행처를 적고, 같은
이름을 이 문서에도 남긴다 — 자물쇠가 둘을 맞춰 본다.

### 들인 인용문

#### 하나 — 제사선(第四禪)

원문 그대로:

> "Furthermore, with the giving up of pleasure and pain and the disappearance
> of former happiness and sadness, a mendicant enters and remains in the
> fourth absorption, without pleasure or pain, with pure equanimity and
> mindfulness."

| | |
|---|---|
| 출전 | Majjhima Nikāya 39 (Mahā-assapurasutta), 구절 `mn39:18.1` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/mn/mn39_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/mn/mn39_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 끝의 공백 한 칸을 지운 것 외에 없다 |

#### 둘 — 무위(無爲)

원문 그대로:

> 為學日益，為道日損。損之又損，以至於無為。

| | |
|---|---|
| 출전 | 도덕경(道德經) 제48장 첫 대목 |
| 라이선스 | 저작권 소멸 — 기원전 성립, 공유 저작물 |
| 대조한 URL | https://ctext.org/dao-de-jing (Chinese Text Project · 원문에 글자가 있는 것을 직접 확인) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 없다. 48장 전문 중 앞 네 구를 그대로 끊어 왔다 |

한문 원문 자체는 저작권이 소멸한 공유 저작물이다. 위 URL 은 라이선스를
주는 곳이 아니라 **글자를 대조한 증거**일 뿐이다. 이어지는 우리말은
번역 인용이 아니라 **자체 산문**이다.

#### 셋 — 눕는 자세

원문 그대로:

> In the middle watch, we will lie down in the lion’s posture—on the right side, placing one foot on top of the other—mindful and aware, and focused on the time of getting up.

| | |
|---|---|
| 출전 | Majjhima Nikāya 39 (Mahā-assapurasutta), 구절 `mn39:10.4` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/mn/mn39_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/mn/mn39_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 앞뒤 공백을 지운 것 외에 없다 |

#### 넷 — 걷는 쉼

원문 그대로:

> You get fit for traveling, fit for striving in meditation, and healthy. What’s eaten, drunk, chewed, and tasted is properly digested. And immersion gained while walking lasts long.

| | |
|---|---|
| 출전 | Aṅguttara Nikāya 5.29 (Caṅkamasutta), 구절 `an5.29:1.3` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/an/an5/an5.29_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/an/an5/an5.29_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 앞뒤 공백을 지운 것 외에 없다 |

#### 다섯 — 앉는 자세

원문 그대로:

> It’s when a mendicant—gone to a wilderness, or to the root of a tree, or to an empty hut—sits down cross-legged, sets their body straight, and brings mindfulness to the present.

| | |
|---|---|
| 출전 | Majjhima Nikāya 118 (Ānāpānassatisutta), 구절 `mn118:17.1` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/mn/mn118_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/mn/mn118_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 앞뒤 공백을 지운 것 외에 없다 |

#### 여섯 — 숨을 몸으로 겪는다

원문 그대로:

> They practice like this: ‘I’ll breathe in experiencing the whole body.’ They practice like this: ‘I’ll breathe out experiencing the whole body.’

| | |
|---|---|
| 출전 | Majjhima Nikāya 118 (Ānāpānassatisutta), 구절 `mn118:18.3` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/mn/mn118_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/mn/mn118_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 앞뒤 공백을 지운 것 외에 없다 |

#### 일곱 — 알아차림

원문 그대로:

> It’s when a mendicant meditates by observing an aspect of the body—keen, aware, and mindful, rid of covetousness and displeasure for the world.

| | |
|---|---|
| 출전 | Majjhima Nikāya 10 (Satipaṭṭhānasutta), 구절 `mn10:3.2` |
| 역자 | **Bhikkhu Sujato** |
| 역자 확인 근거 | 파일 경로에 역자가 박혀 있다: `translation/en/**sujato**/sutta/mn/mn10_translation-en-**sujato**.json` |
| 받은 URL | https://raw.githubusercontent.com/suttacentral/bilara-data/published/translation/en/sujato/sutta/mn/mn10_translation-en-sujato.json (HTTP 200) |
| 라이선스 | CC0 1.0 (위 확인 참조) |
| 확인 일자 | 2026-08-27 |
| 손댄 곳 | 원문 앞뒤 공백을 지운 것 외에 없다 |

## 아홉 자리 — 구주심(九住心)

`data/nine_abidings.yml` 의 글은 인용이 아니라 **이 앱의 산문** 이다. 옛글을
옮겨 적지 않았고, 자리의 이름과 짜임만 옛글에서 왔다.

| | |
|---|---|
| 짜임의 출전 | 무착(Asaṅga) 『성문지(聲聞地, Śrāvakabhūmi)』 · 『대승장엄경론(Mahāyānasūtrālaṃkāra)』 열넷째 장 |
| 육력(六力) · 사작의(四作意)의 배대 | 티베트 람림 전통 — 종카파 『보리도차제론(Lamrim Chenmo)』 에서 정착된 해석 |
| 코끼리 그림 | 같은 전통의 탕카 도상. 그림에 대한 서술만 있고 그림 파일은 없다 |
| 자리의 이름 | 한자 · 한글 · 산스크리트 · 영어 풀이. 낱말은 옛글의 것이다(SPIRIT §5) |
| 한국어 · 영어 산문 | 각각 그 언어로 쓴 문장이다. 번역이 아니다 |
| 자물쇠 | `test/locks/form/abiding_test.rb` — 카피와 같은 자물쇠(가르침 · 숫자 · 느낌표 · 이모지)를 전 칸에 건다 |

**옛글의 낱말.** 육력(六力)과 사작의(四作意)의 이름 — `power` · `engagement`
칸 — 은 『성문지』의 용어이지 앱이 사용자에게 하는 말이 아니다. 그래서
「정진력(精進力)」의 「정진」은 가르침의 자물쇠 밖에 있다. 「인용 원문은
예외다. 옛글의 낱말은 옛글의 것이다」(SPIRIT §5)를 그 두 칸에 적용한
것이고, 새 예외를 둔 것이 아니다. 숫자 · 느낌표 · 이모지의 자물쇠는 그
두 칸에도 그대로 걸린다.

## 글꼴

큰 글은 붓이다(2026-10-08). 셋 다 SIL Open Font License 1.1 이고, 파일은 `app/assets/fonts/`
에 OFL 전문과 함께 있다. **글꼴 서비스를 부르지 않는다** — 저장소에서 낸다(제6조,
`type_test` 「붓 셋은 저장소 안의 파일이다」). 작은 글(읽는 글 · 손잡이 · 보조)은 붓이 아니라
기기의 고딕이다 — 붓은 13px 아래에서 읽히지 않는다.

| 글꼴 | 자리 | 만든 이 | 받은 곳 | 추린 글자 | 파일 |
|---|---|---|---|---|---|
| 동해독도(East Sea Dokdo) | 한글 큰 글 | 윤디자인 | github.com/google/fonts `ofl/eastseadokdo` (`EastSeaDokdo-Regular.ttf`, 3,178,684 바이트) | 라틴 · 한글 음절 · 자모 · 문장부호 — 원본에 한글 2,484자, 한자 없음 | `EastSeaDokdo.woff2` 232,220 바이트 |
| Caveat Brush | 알파벳 큰 글 | Pablo Impallari | github.com/google/fonts `ofl/caveatbrush` (`CaveatBrush-Regular.ttf`, 295,568 바이트) | U+0020–007E · 00A0–00FF · 2000–206F | `CaveatBrush.woff2` 67,088 바이트 |
| LXGW WenKai TC(霞鶩文楷 TC) | 한자 — 현판 · 전각 이름의 곁말 · 사경의 본보기 글자 | LXGW WenKai Project(落霞孤鶩), Klee One(Fontworks) 바탕 | github.com/lxgw/LxgwWenkaiTC 릴리스 1.522 (`LXGWWenKaiTC-Regular.ttf`, 15,267,616 바이트) | 앱이 쓰는 한자 155자(사경 · 현판 · 전각)와 CJK 문장부호 — 217자, 빠진 글자 없음 | `WenKaiTC.woff2` 54,852 바이트 |

받은 날은 셋 다 2026-10-08. 추리는 손은 fontTools(`python3 -m fontTools.subset`)이고,
원본 TTF 는 저장소에 두지 않는다 — 글자를 더 넣어야 하면 위 주소에서 다시 받아 추린다.

한자는 처음 Yuji Syuku(일본 붓 해서, OFL)로 들였다가 같은 날 WenKai TC 로 바꿨다 — Yuji 는 일본 자형이라
155자 중 23자(艹 · 辶 · 戶 · 示 · 者의 점 · 虛 · 鼻 · 益)가 한국 자형과 달랐고 넉 자(內 埵 罣 說)가 없었다.
WenKai TC 는 전승 자형이라 155자가 모두 한국 자형과 같고(爲 · 眞 · 卽도 그 꼴로 선다) 빠진 글자가 없다.
붓 맛은 Yuji 보다 옅다 — 붓보다 교과서 해서에 가깝다.

**추림과 OFL(2026-10-08 확인).** 추린 woff2 는 OFL 이 말하는 「Modified Version」이다. OFL §3 은
수정본에 **Reserved Font Name** 을 쓰지 못하게 하는데, 셋 다 동봉한 OFL 전문 첫 줄(저작권
표시)에 Reserved Font Name 선언이 없다 — 구글 폰트는 올리는 글꼴에서 예약 이름을 뺀다.
그래서 내부 이름(East Sea Dokdo · Caveat Brush · LXGW WenKai TC)을 바꾸지 않고 둔다. 동해독도의
윤디자인 원 저장소(github.com/yoondesign/Yoonfont-KoreaDokdo)에는 「Reserved Font Name
"KoreaDokdo"」가 있으나, 우리가 받은 것은 그 이름을 쓰지 않는 구글 폰트 쪽 배포본이고 그
OFL 전문을 동봉했다. 「동해독도체」라는 이름의 동해시 배포본은 받지 않았다 — 조건이 다를
수 있어 쓰지 않는다.
