# This app is a raft. — 이 앱도 뗏목이다.
#
# 대조한 인용 — 원문을 눈으로 보고 올린 것만 여기 있다.
#
# **표에 올린다는 것이 「대조했다」는 표시다.** 요약글이나 기억에서 옮긴 문장은
# 올리지 않는다. 경에 없는 말에 경의 이름을 붙이는 것은 사용자가 배신당하는
# 자리이므로, 이것은 결이 아니라 약속이다(citation_test).
#
# 한 줄에 담는 것:
#   ko · en     화면에 나가는 문장. 로케일의 그것과 글자 그대로 같아야 한다.
#   source_*    붙이는 출전. compound_controller.js 의 것과 같아야 한다.
#   original    원문. 옮긴 말이 아니라 그 말이 나온 자리의 글자.
#   edition     어느 판본의 글자인가. 판본에 따라 글자가 갈리기 때문이다.
#   seen        원문을 본 곳. 다음 사람이 같은 자리를 다시 열 수 있게.
#   rendered_by 화면의 문장을 누가 옮겼는가. **원문은 저작권이 없지만 번역은 있다.**
#               「이 앱」이면 자체 산문이라 그대로 쓴다(docs/SOURCES.md 의 규칙 —
#               한국어는 번역을 인용하지 않고 자체 산문으로 쓴다). 남의 번역본을
#               가져온 줄이 있으면 역자와 발행처를 여기 적고 SOURCES.md 에도 남긴다.
#   checked_on  대조한 날.
#
# 출전을 새로 달려면 먼저 원문을 열어 보고 이 표에 한 줄을 더한다. 표에 없는
# 출전이 화면에 서면 자물쇠가 깨진다.
module Citation
  CHECKED = {
    sitting: {
      ko: "길들여진 마음이 즐거움을 가져온다",
      en: "A tamed mind brings happiness",
      source_ko: "『법구경』 35",
      source_en: "Dhammapada 35",
      original: "Cittassa damatho sādhu, cittaṁ dantaṁ sukhāvahaṁ.",
      edition: "Mahāsaṅgīti 판 팔리 원문(SuttaCentral bilara-data, dhp35:3–4)",
      seen: "https://suttacentral.net/api/bilarasuttas/dhp33-43/sujato",
      rendered_by: "이 앱 — 원문을 보고 옮긴 자체 산문",
      checked_on: "2026-10-07"
    },
    copying: {
      ko: "이 경이 있는 곳에는 곧 부처가 계신다",
      en: "Where this sūtra is, the Buddha is there",
      source_ko: "『금강경』 제12 존중정교분",
      source_en: "Diamond Sūtra, ch. 12",
      # 판본에 따라 則과 即이 갈린다. 대정장은 則이고, 그 자리에 교감주가 붙어
      # 있지 않다 — 대교본들 사이에 이 글자의 이동(異同)이 기록되어 있지 않다는 뜻이다.
      # 위키문헌에서 본 即은 그 판본이 그런 것이지 틀린 것이 아니다.
      original: "若是經典所在之處，則為有佛，若尊重弟子。",
      edition: "대정장 T08n0235 권1, 0750a09–10(구마라집 역) — CBETA 원본 XML",
      seen: "https://raw.githubusercontent.com/cbeta-git/xml-p5/master/T/T08/T08n0235.xml",
      rendered_by: "이 앱 — 원문을 보고 옮긴 자체 산문",
      checked_on: "2026-10-07"
    },
    lecture: {
      ko: "열반이 으뜸가는 즐거움",
      en: "Nibbāna is the highest happiness",
      source_ko: "『법구경』 204",
      source_en: "Dhammapada 204",
      original: "Nibbānaṁ paramaṁ sukhaṁ.",
      edition: "Mahāsaṅgīti 판 팔리 원문(SuttaCentral bilara-data, dhp204:4)",
      seen: "https://suttacentral.net/api/bilarasuttas/dhp197-208/sujato",
      rendered_by: "이 앱 — 원문을 보고 옮긴 자체 산문",
      checked_on: "2026-10-07"
    },
    gate: {
      ko: "나는 멈추었다",
      en: "I have stopped",
      source_ko: "『앙굴리말라경』 MN 86",
      source_en: "Aṅgulimāla Sutta, MN 86",
      original: "Ṭhito ahaṁ, aṅgulimāla, tvañca tiṭṭhā.",
      edition: "Mahāsaṅgīti 판 팔리 원문(SuttaCentral bilara-data, mn86:5.9)",
      seen: "https://suttacentral.net/api/bilarasuttas/mn86/sujato",
      rendered_by: "이 앱 — 원문을 보고 옮긴 자체 산문",
      checked_on: "2026-10-07"
    }
  }.freeze

  def self.[](key) = CHECKED[key.to_sym]

  def self.checked?(key) = CHECKED.key?(key.to_sym)
end
