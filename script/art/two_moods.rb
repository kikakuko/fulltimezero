# This app is a raft. — 이 앱도 뗏목이다.
#
# 두 결(docs/art-style.md) — 문 밖은 B(사진 같은 회화), 문 안은 D(한지 위 먹선과 옅은 담채, B 의 구도와 빛).
# 경계는 일주문이다. 셋을 한 장씩 부른다. 고르는 것은 사람이다. 원본은 tmp/art/ 에만.
#   ruby script/art/two_moods.rb ga        — B-일주문(지금 B 시안을 다듬는다)
#   ruby script/art/two_moods.rb na        — D2-일주문((가)를 구도 참조로, 재료만 D)
#   ruby script/art/two_moods.rb og        — og 그림(B, 16:9 로 뽑아 1200×630 으로 자른다)
#   ruby script/art/two_moods.rb d3a d3b   — D3-일주문 두 장(결은 A 시안과 우리 그림, (가)는 자리만)
#   ruby script/art/two_moods.rb ogfix     — og 고침(다시 뽑지 않고 편집 한 번: 마당의 차를 지운다)
#   ruby script/art/two_moods.rb d3c       — D3c-일주문(2026-11-06 톤 고침: 재료는 A, 색과 명암은 D 시안, D3a 는 자리만)
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
ART = File.join(ROOT, "tmp/art")
REFS = File.join(ART, "refs")

# 두 결이 함께 지키는 것(art-style.md 「둘 다」).
FORBIDDEN = "Do not include: elephants, the moon, a Maitreya statue, pagodas (the app draws these separately), people, " \
            "animals, any writing or letters, signboard calligraphy (leave the signboard blank), seals, the sun, modern " \
            "objects (cars and other vehicles, utility poles, wires, signboards, signs, fences, lamps, modern buildings), " \
            "or any frame or border."
# B 가 늘 지키는 산세.
KOREAN_MOUNTAINS = "The mountains are Korean: soft rounded ridges layered one behind another, pine trees, and mist " \
                   "between the ridges. No Alpine rock spires, no fir or spruce forests."
B = "Style B: a photorealistic painting. Light and materials feel real — early morning light slanting in, mist — with " \
    "only a few brush marks left visible, so it reads as a painting rather than a photograph."
D = "Style D: ink lines and pale washes of color on hanji paper, with the composition and light of a realistic painting. " \
    "Dancheong colors are subdued into pale washes. The ground at the bottom — the dirt path, moss and fallen leaves — is " \
    "also painted in pale washes, not rendered photographically."
# D3 — 먹선과 한지가 또렷한 쪽. 빛줄기까지 먹의 번짐으로.
D3 = "Style: clear ink outlines on hanji paper, flat areas of pale wash, the fibers of the hanji visible throughout. " \
     "Even the shafts of morning light are rendered as soft bleeding of ink and wash. No photographic texture at all — " \
     "no photographic depth of field, no photographic grain, no realistic material rendering."
# D3c — 새 결의 기준(art-style 2절, 2026-11-06). 재료는 A(먹선 · 한지 결 · 평평한 담채 면), 색과 명암은 D 시안.
D3C = "Style: the materials are those of ink painting on hanji — clear ink outlines, the fibers of the hanji visible " \
      "throughout, color laid in flat areas of wash. No photographic texture at all — no photographic depth of field, " \
      "no photographic grain, no realistic material rendering. But the color and the light are full, not washed out: " \
      "the pine needles are a deep, dark green; the pillars of the gate are clearly red; the tree trunks are dark; the " \
      "morning light is warm; the shadows on the path, under the eaves and among the trees are distinct. The bare white " \
      "of the paper shows only in the sky and the mist — everywhere else the paper is covered with wash. Dancheong is " \
      "muted, not bright. No gold anywhere."
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
  "d3a" => {
    name: "gate-d3a", aspect: "3:4",
    prompt: [ "Use the references only for these roles: the first three set the medium and style (ink lines, hanji, " \
              "pale washes); the fourth sets only the placement and size of the gate, the trees and the path — match " \
              "those positions and sizes exactly, but do not follow its colors or its materials at all.",
              GATE, D3, KOREAN_MOUNTAINS, FORBIDDEN ],
    references: [ File.join(ART, "realism-a-ink-1.jpeg"), File.join(ROOT, "app/assets/images/elephant_field.webp"),
                  File.join(ROOT, "app/assets/images/mireukdang.webp"), File.join(ART, "gate-b-1.jpeg") ]
  },
  "d3c" => {
    name: "gate-d3c", aspect: "3:4",
    prompt: [ "Use the references only for these roles: the first sets the color and the values — how dark, how warm, how " \
              "much contrast and shadow, where the white of the paper is left; the second sets only the materials (ink " \
              "outlines, hanji fibers, flat washes) — do not follow its pale washed-out color; the third sets only the " \
              "placement and size of the gate, the trees and the path — match those positions and sizes exactly.",
              GATE, D3C, KOREAN_MOUNTAINS, FORBIDDEN ],
    references: [ File.join(ART, "realism-d-ink-framed-1.jpeg"), File.join(ART, "realism-a-ink-1.jpeg"),
                  File.join(ART, "gate-d3a-1.jpeg") ]
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
}.merge(
  # 둘째 장 — 같은 문장 · 같은 참조, 이름만 다르다.
  "d3b" => nil,
  # og 고침 — 그림을 넣고 그 자리만 바꾼다. 나머지는 그대로 두라고 이른다.
  "ogfix" => {
    name: "og-b-fixed", aspect: "16:9",
    prompt: [ "Edit this image. In the temple courtyard at the right end of the cluster of roofs there are two small " \
              "car-like vehicles. Remove both of them and fill that spot with bare dirt courtyard and trees, matching " \
              "the surrounding painting. Change nothing else: keep every roof, ridge, tree, the mist, the light, the " \
              "colors and the framing exactly as they are.", FORBIDDEN ],
    references: [ File.join(ART, "og-b-1.jpeg") ]
  }
).then { |runs| runs.merge("d3b" => runs["d3a"].merge(name: "gate-d3b")) }.freeze

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
