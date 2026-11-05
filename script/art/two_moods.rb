# This app is a raft. — 이 앱도 뗏목이다.
#
# 두 결(docs/art-style.md) — 문 밖은 B(사진 같은 회화), 문 안은 D(한지 위 먹선과 옅은 담채, B 의 구도와 빛).
# 경계는 일주문이다. 셋을 한 장씩 부른다. 고르는 것은 사람이다. 원본은 tmp/art/ 에만.
#   ruby script/art/two_moods.rb ga        — B-일주문(지금 B 시안을 다듬는다)
#   ruby script/art/two_moods.rb na        — D2-일주문((가)를 구도 참조로, 재료만 D)
#   ruby script/art/two_moods.rb og        — og 그림(B, 16:9 로 뽑아 1200×630 으로 자른다)
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
ART = File.join(ROOT, "tmp/art")
REFS = File.join(ART, "refs")

# 두 결이 함께 지키는 것(art-style.md 「둘 다」).
FORBIDDEN = "Do not include: elephants, the moon, a Maitreya statue, pagodas (the app draws these separately), people, " \
            "animals, any writing or letters, signboard calligraphy (leave the signboard blank), seals, the sun, modern " \
            "objects (signs, fences, lamps, cars, wires), or any frame or border."
# B 가 늘 지키는 산세.
KOREAN_MOUNTAINS = "The mountains are Korean: soft rounded ridges layered one behind another, pine trees, and mist " \
                   "between the ridges. No Alpine rock spires, no fir or spruce forests."
B = "Style B: a photorealistic painting. Light and materials feel real — early morning light slanting in, mist — with " \
    "only a few brush marks left visible, so it reads as a painting rather than a photograph."
D = "Style D: ink lines and pale washes of color on hanji paper, with the composition and light of a realistic painting. " \
    "Dancheong colors are subdued into pale washes. The ground at the bottom — the dirt path, moss and fallen leaves — is " \
    "also painted in pale washes, not rendered photographically."
GATE = "Early morning at the end of a forest path. A Korean temple one-pillar gate (iljumun) stands squarely in the " \
       "center, seen straight on, between tall pine trees; beyond the gate the path runs on beneath it and disappears " \
       "into the mist. Leave the upper third of the picture open with sky, mist and distant ridges."

RUNS = {
  "ga" => {
    name: "gate-b", aspect: "3:4",
    prompt: [ "Use the references only for these roles: the first for the gate's structure and proportions; the second " \
              "for the rendering and the composition; the third for the shapes of the mountains.",
              GATE, KOREAN_MOUNTAINS, B, FORBIDDEN ],
    references: [ File.join(REFS, "R22.jpg"), File.join(ART, "realism-b-painterly-1.jpeg"), File.join(REFS, "R03.jpg") ]
  },
  "na" => {
    name: "gate-d2", aspect: "3:4",
    prompt: [ "Repaint the first reference exactly — the same gate in the same place and size, the same trees, the same " \
              "path, the same light — changing only the medium. Use the second reference only for the medium (ink and " \
              "pale washes on hanji) and the third only for the app's palette.",
              D, KOREAN_MOUNTAINS, FORBIDDEN ],
    references: [ File.join(ART, "gate-b-1.jpeg"), File.join(ART, "realism-d-ink-framed-1.jpeg"), File.join(ROOT, "app/assets/images/mireukdang.webp") ]
  },
  "og" => {
    name: "og-b", aspect: "16:9",
    prompt: [ "Use the references only for these roles: the first for the rendering; the second for the shapes of the " \
              "mountains; the third for the Korean temple buildings.",
              "A Korean mountain temple seen from far away: a small cluster of tiled roofs on a wooded slope, rounded ridges " \
              "layered into the distance, morning mist in the valleys. Keep the temple in the lower middle and leave the " \
              "upper part of the picture open with soft sky and mist. Wide landscape, quiet and spacious.",
              KOREAN_MOUNTAINS, B, FORBIDDEN ],
    references: [ File.join(ART, "realism-b-painterly-1.jpeg"), File.join(REFS, "R03.jpg"), File.join(REFS, "R30.jpg") ]
  }
}.freeze

chosen = RUNS.slice(*ARGV)
abort "부를 것을 고른다: #{RUNS.keys.join(" · ")}" if chosen.empty?
abort "한 번에 #{MonoRouter::MOST_PER_RUN} 장까지" if chosen.size > MonoRouter::MOST_PER_RUN

chosen.each_value do |run|
  missing = run[:references].reject { |path| File.exist?(path) }
  abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

  paths, spent = MonoRouter.draw(name: run[:name], model: MODEL, prompt: run[:prompt].join("\n\n"),
                                 size: "1K", aspect: run[:aspect], references: run[:references])
  puts "#{run[:name]}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{run[:name]}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
