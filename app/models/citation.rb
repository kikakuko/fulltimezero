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
#   seen        원문을 본 곳. 다음 사람이 같은 자리를 다시 열 수 있게.
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
      seen: "https://suttacentral.net/dhp33-43/pli/ms",
      checked_on: "2026-10-07"
    },
    copying: {
      ko: "이 경이 있는 곳에는 곧 부처가 계신다",
      en: "Where this sūtra is, the Buddha is there",
      source_ko: "『금강경』 제12 존중정교분",
      source_en: "Diamond Sūtra, ch. 12",
      original: "若是經典所在之處，即為有佛，若尊重弟子。",
      seen: "https://zh.wikisource.org/wiki/金剛般若波羅蜜經_(鳩摩羅什)",
      checked_on: "2026-10-07"
    },
    lecture: {
      ko: "열반이 으뜸가는 즐거움",
      en: "Nibbāna is the highest happiness",
      source_ko: "『법구경』 204",
      source_en: "Dhammapada 204",
      original: "Nibbānaṁ paramaṁ sukhaṁ.",
      seen: "https://suttacentral.net/dhp197-208/pli/ms",
      checked_on: "2026-10-07"
    },
    gate: {
      ko: "나는 멈추었다",
      en: "I have stopped",
      source_ko: "『앙굴리말라경』 MN 86",
      source_en: "Aṅgulimāla Sutta, MN 86",
      original: "Ṭhito ahaṁ, aṅgulimāla, tvañca tiṭṭhā.",
      seen: "https://suttacentral.net/mn86/pli/ms",
      checked_on: "2026-10-07"
    }
  }.freeze

  def self.[](key) = CHECKED[key.to_sym]

  def self.checked?(key) = CHECKED.key?(key.to_sym)
end
