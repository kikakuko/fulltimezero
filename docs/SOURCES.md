# 콘텐츠 출처와 라이선스

이 앱에 들어오는 인용문·경전 원문·소리는 **CC0(또는 공유 저작물) 원문만**
쓴다. 번역·주석에 저작권이 있는 판본은 쓰지 않는다.

인용문을 하나 들일 때마다 아래에 한 줄을 남긴다:
원문 그대로의 문장 · 출전 · 라이선스 · 확인한 날짜.

`test/integration/spirit_test.rb` 가 「쉼의 안내」의 인용문이 이 목록에
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
**원문 제목 · 출처 URL · 라이선스(CC0만) · 확인한 날짜.**
번역·주석·편곡에 저작권이 있는 판본은 쓰지 않는다.

- (아직 없음)

## 인용문

인용은 **CC0 원문 또는 저작권이 소멸한 원문만.** 번역·주석·편곡에
저작권이 있는 판본은 쓰지 않는다. 한국어는 인용하지 않고 자체 산문으로
쓴다 — 현대 한글 번역본에는 저작권이 있다.

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
| 자물쇠 | `test/models/abiding_test.rb` — 카피와 같은 자물쇠(가르침 · 숫자 · 느낌표 · 이모지)를 전 칸에 건다 |

**옛글의 낱말.** 육력(六力)과 사작의(四作意)의 이름 — `power` · `engagement`
칸 — 은 『성문지』의 용어이지 앱이 사용자에게 하는 말이 아니다. 그래서
「정진력(精進力)」의 「정진」은 가르침의 자물쇠 밖에 있다. 「인용 원문은
예외다. 옛글의 낱말은 옛글의 것이다」(SPIRIT §5)를 그 두 칸에 적용한
것이고, 새 예외를 둔 것이 아니다. 숫자 · 느낌표 · 이모지의 자물쇠는 그
두 칸에도 그대로 걸린다.
