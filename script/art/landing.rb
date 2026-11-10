# This app is a raft. — 이 앱도 뗏목이다.
#
# 첫 화면 그림 묶음(docs/M-landing-design.md 13절, 2026-11-06). 톤은 새 규칙 — 재료는 A, 색과 명암은 D3c(기준 그림).
# 참조 차례: D3c(색과 명암) · 시안 A(재료) · 그 그림의 지난 시안(자리). 원경만 B(문 밖) — B 의 참조로 그린다.
# 현판은 비워 둔다(앱이 글자를 얹는다). 한 번에 넷까지라 둘로 나눠 부른다. 원본은 tmp/art/ 에만.
#   ruby script/art/landing.rb walls     — 천왕문 왼쪽 벽 둘 · 오른쪽 벽 하나 · 선방 방 하나
#   ruby script/art/landing.rb outer     — 원경(B) 둘 · 불이문(D) 둘
#   ruby script/art/landing.rb fix       — 원경 far-b 편집 한 번(먼 산 중턱에 절) · 오른쪽 벽 다시 한 장(뒷벽 · 바닥을 ④ 처럼)
#   ruby script/art/landing.rb aerial    — 원경 새로(B, 아주 높이서 비스듬히 내려다봄) 두 장 — 화면 아래 숲 가장자리에 작은 일주문
#   ruby script/art/landing.rb robe      — 오른쪽 벽 c 의 칼 든 천왕 옷만 편집 한 번(옅은 황토 → 옅은 청록 · 주황 담채)
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
ART = File.join(ROOT, "tmp/art")
REFS = File.join(ART, "refs")
D3C = File.join(ROOT, "docs/sources/art/gate-d3c.jpg")
A = File.join(ART, "realism-a-ink-1.jpeg")

ROLES = "Use the references only for these roles: the first sets the color and the values — how dark, how warm, how " \
        "much contrast and shadow, where the white of the paper is left; the second sets only the materials (ink outlines, " \
        "hanji fibers, flat washes) — do not follow its pale washed-out color; the third sets only the composition — the " \
        "placement and size of everything in it — match it closely."
STYLE = "Style: the materials are those of ink painting on hanji — clear ink outlines, the fibers of the hanji visible " \
        "throughout, color laid in flat areas of wash. No photographic texture at all. But the color and the light are " \
        "full, not washed out, like the first reference: dark wood, clearly red pillars, deep green pines, warm morning " \
        "light, distinct shadows. The bare white of the paper shows only in sky, mist or light — everywhere else the " \
        "paper is covered with wash. Dancheong is muted, not bright. No gold or gilded color anywhere."
FORBIDDEN = "Do not include: gold or gilded color, any writing, letters, signboard calligraphy (leave every signboard blank), " \
            "name plates, seals, people, trampled demons or small figures under the feet, the sun, the moon, elephants, a " \
            "Maitreya statue, pagodas other than the one small pagoda a Heavenly King holds, animals other than the one " \
            "dragon a Heavenly King holds, modern objects (lamps, lamp posts, signs, wires, metal fences, cars), or any outer " \
            "frame or border around the picture."
KINGS = "Inside the Cheonwangmun (Heavenly Kings Gate), seen straight on from the central passage, facing one side wall. " \
        "Behind a low plain wooden rail, two of the Four Heavenly Kings sit side by side as large painted wooden statues " \
        "in the Korean late-Joseon manner — tall flower-and-flame crowns, round eyes, patterned armor, long sashes rising " \
        "behind the shoulders. Their faces are dignified and calm, protective, not frightening. Their feet rest on low " \
        "plain rocks."
KOREAN_MOUNTAINS = "The mountains are Korean: soft rounded ridges layered one behind another, pine trees, and mist between " \
                   "the ridges. No Alpine rock spires, no fir or spruce forests."
B = "Style B: a photorealistic painting. Light and materials feel real — early morning light slanting in, mist — with only " \
    "a few brush marks left visible, so it reads as a painting rather than a photograph."

# 원경 — 아주 높이서 비스듬히 내려다본 B. og 그림(og/ko.jpg 의 원본)이 결과 장면의 첫째 참조다.
AERIAL_REFS = [ File.join(ART, "og-b-fixed-1.jpeg"), File.join(REFS, "R03.jpg"), File.join(ART, "gate-b-1.jpeg") ].freeze
AERIAL_ROLES = "Use the references only for these roles: the first for the scene, the rendering, the light and the colors " \
               "— this picture is the same world seen from much higher and farther away; the second for the shapes of the " \
               "mountains; the third only for what the small one-pillar gate looks like."
AERIAL = "A bird's-eye view from very high up and far away, looking obliquely down over layered soft rounded Korean " \
         "mountain ranges in morning mist. Around the middle of the picture, a small Korean mountain temple — a cluster of " \
         "dark tiled roofs — nestles small on a mountain slope. Below it, a forest path winds down through the trees, and " \
         "near the bottom of the picture, at the edge of the forest, one small one-pillar temple gate (iljumun) stands on " \
         "the path, tiny in the landscape. The upper third of the picture is open sky and mist. Much higher and farther " \
         "away than an ordinary aerial view of a temple courtyard — the temple and the gate are small."
AERIAL_FORBIDDEN = FORBIDDEN + " No spiky pointed conifer forests (fir or spruce), no people, no cars, no letters, no sun, no moon."

def wall(previous) = [ D3C, A, File.join(ART, previous) ]

RUNS = {
  "walls" => {
    "cheonwang-left-c" => [ wall("cheonwang-left-b-1.jpeg"),
      [ ROLES, KINGS, "The king on the left holds a long Korean dragon coiling around one arm and a small round jewel in the " \
        "other hand; the king on the right holds a long pole with a narrow hanging banner and raises a small multi-storied " \
        "pagoda on his palm. Both are mature men with full beards and moustaches, the same age as the kings on the other " \
        "wall. Their two faces are clearly different from each other: the left one broad with a thick dark beard and heavy " \
        "brows, the right one longer with a lighter, forked beard.", STYLE, FORBIDDEN ] ],
    "cheonwang-left-d" => [ wall("cheonwang-left-b-1.jpeg"),
      [ ROLES, KINGS, "The king on the left holds a long Korean dragon coiling around one arm and a small round jewel in the " \
        "other hand; the king on the right holds a long pole with a narrow hanging banner and raises a small multi-storied " \
        "pagoda on his palm. Both are mature bearded men. Give them distinctly different faces: the left one with a round " \
        "face, curling beard and wide-set eyes; the right one with a narrow face, long straight beard and a calm steady gaze.",
        STYLE, FORBIDDEN ] ],
    "cheonwang-right-c" => [ wall("cheonwang-right-b-1.jpeg"),
      [ ROLES, KINGS, "The king on the left holds a bipa (a Korean pear-shaped four-string lute) across his body and plucks " \
        "it. The king on the right holds a straight sword diagonally across his chest, the other hand on his hip. Both are " \
        "mature bearded men with different faces. The robes and armor of the sword-holding king are in pale washes of " \
        "blue-green, muted red and soft ochre-brown — no yellow-gold, no gilded trim.", STYLE, FORBIDDEN ] ],
    "seonbang-room4" => [ [ D3C, A, File.join(ART, "seonbang-room3-1.jpeg") ],
      [ ROLES, "Keep the same room, viewpoint and composition as the third reference exactly: a Korean meditation hall seen " \
        "straight on, paper-covered lattice doors at the sides with morning light, a wooden floor with rows of empty low " \
        "square cushions, and the large hanging scroll on the front wall in exactly the same place and size. The picture " \
        "area inside the scroll's mounting stays completely blank hanji paper — paint nothing inside it. Make the room " \
        "darker and warmer than the third reference — wood in warm brown washes, soft shadows in the corners and under " \
        "the cushions — but keep it a little lighter and quieter than the first reference, because the scroll is the main " \
        "thing in this picture. The scroll's mounting stays a very pale grey-blue.", STYLE, FORBIDDEN ] ]
  },
  "fix" => {
    "far-b-temple" => [ [ File.join(ART, "far-b-1.jpeg") ],
      [ "Edit this image. On the slope of the middle-distance mountain, in the center of the picture, add a few small " \
        "Korean temple roofs (dark grey tiled roofs, a small cluster of three or four buildings) half hidden in the mist, " \
        "small and far away, so that the dirt path in the foreground seems to lead toward them through the forest. " \
        "Change nothing else: keep every ridge, the mist, the river, the pine trees, the path, the light, the colors and " \
        "the framing exactly as they are.", B, FORBIDDEN ] ],
    "cheonwang-right-d" => [ [ D3C, A, File.join(ART, "cheonwang-right-c-robe-1.jpeg"), File.join(ART, "cheonwang-left-c-1.jpeg") ],
      [ "Use the references only for these roles: the first sets the color and the values; the second sets only the " \
        "materials (ink outlines, hanji fibers, flat washes); the third sets the composition, the two kings, what they " \
        "hold and the colors of their robes — keep the sword-holding king's robes in the same pale blue-green and soft " \
        "orange washes, no yellow or gold; the fourth is the opposite wall of the same gate hall — make the back wall, " \
        "the rafters, the rail and the floor the same warm dark wood as in it, so the two walls match.",
        KINGS, "The king on the left holds a bipa (a Korean pear-shaped four-string lute) across his body and plucks it. " \
        "The king on the right holds a straight sword diagonally across his chest, the other hand on his hip. Both are " \
        "mature bearded men with different faces. The back wall is warm dark wood, not white; the floor is dark wood.",
        STYLE, FORBIDDEN ] ]
  },
  "aerial" => {
    "aerial-a" => [ AERIAL_REFS, [ AERIAL_ROLES, AERIAL, KOREAN_MOUNTAINS, B, AERIAL_FORBIDDEN ] ],
    "aerial-b" => [ AERIAL_REFS, [ AERIAL_ROLES, AERIAL + " Let the path make one or two wide bends so the eye follows it " \
                                   "from the gate up to the temple.", KOREAN_MOUNTAINS, B, AERIAL_FORBIDDEN ] ]
  },
  "robe" => {
    "cheonwang-right-c-robe" => [ [ File.join(ART, "cheonwang-right-c-1.jpeg") ],
      [ "Edit this image. The Heavenly King on the right, holding the sword, wears robes and armor in pale yellow-ochre " \
        "that read as gold. Repaint only his robes, sleeves, sashes and armor in pale washes of blue-green (celadon) and " \
        "soft orange-vermilion, like the dancheong of the king on the left — no yellow, no gold. Keep his face, crown, " \
        "sword, pose and outlines exactly as they are, and change nothing else in the picture: the other king, the rail, " \
        "the walls, the light and the framing stay exactly the same.", FORBIDDEN ] ]
  },
  "outer" => {
    "far-a" => [ [ File.join(ART, "gate-b-1.jpeg"), File.join(REFS, "R03.jpg"), File.join(REFS, "R30.jpg") ],
      [ "Use the references only for these roles: the first for the rendering, the light and the colors; the second for " \
        "the shapes of the mountains; the third only for how a Korean mountain temple sits far away in a valley.",
        "Early morning, far away from a Korean mountain temple. Layered soft rounded ridges fill the picture, mist lying " \
        "in the valleys. A narrow dirt path starts in the foreground among pine trees and winds into the forest toward " \
        "the mountains. The temple itself is hidden — at most one small tiled roof shows far away between the ridges. " \
        "Leave the upper third open with sky, mist and distant ridges.", KOREAN_MOUNTAINS, B, FORBIDDEN ] ],
    "far-b" => [ [ File.join(ART, "gate-b-1.jpeg"), File.join(REFS, "R03.jpg"), File.join(REFS, "R30.jpg") ],
      [ "Use the references only for these roles: the first for the rendering, the light and the colors; the second for " \
        "the shapes of the mountains; the third only for how a Korean mountain temple sits far away in a valley.",
        "Early morning. Standing at the edge of a pine forest, looking toward deep mountains: many layered rounded ridges " \
        "fading into mist, a stream valley below. A dirt path enters the pine forest in the lower middle, the same kind of " \
        "path that later leads to the one-pillar gate. No temple is visible. Leave the upper third open with sky and mist.",
        KOREAN_MOUNTAINS, B, FORBIDDEN ] ],
    "burimun-a" => [ [ D3C, A, File.join(REFS, "R42.jpg") ],
      [ ROLES.sub("sets only the composition — the placement and size of everything in it — match it closely",
                  "sets only the kind of building — a Korean gate hall with a deep tiled roof, plain round wooden pillars and " \
                  "a central passage — do not copy its people, signs, lamp post or its black-and-white photograph look"),
        "Inside the temple grounds, early morning. The Burimun (Gate of Non-Duality) stands squarely in the center, seen " \
        "straight on across a packed-earth path: a gate hall with a deep curved tiled roof, plain dark wooden pillars and " \
        "an open central passage. Through the passage, faintly, the courtyard of the main hall beyond, bright with " \
        "morning light. A blank wooden signboard hangs under the eaves above the passage — leave it blank. Pine trees at " \
        "the sides, stone steps up to the gate.", STYLE, FORBIDDEN ] ],
    "burimun-b" => [ [ D3C, A, File.join(REFS, "R42.jpg") ],
      [ ROLES.sub("sets only the composition — the placement and size of everything in it — match it closely",
                  "sets only the kind of building — a Korean gate hall with a deep tiled roof, plain round wooden pillars and " \
                  "a central passage — do not copy its people, signs, lamp post or its black-and-white photograph look"),
        "Inside the temple grounds, early morning. Looking up a few broad stone steps at the Burimun (Gate of " \
        "Non-Duality): a gate hall with a deep curved tiled roof, dark wooden pillars and an open central passage, seen " \
        "straight on and a little from below. Beyond the passage, softly lit, the open courtyard. A blank wooden signboard " \
        "under the eaves — leave it blank. Old pines lean in from both sides; their shadows fall across the steps.",
        STYLE, FORBIDDEN ] ]
  }
}.freeze

chosen = RUNS.slice(*ARGV).values.reduce({}, :merge)
abort "부를 것을 고른다: #{RUNS.keys.join(" · ")}" if chosen.empty?
abort "한 번에 #{MonoRouter::MOST_PER_RUN} 장까지" if chosen.size > MonoRouter::MOST_PER_RUN

chosen.each do |name, (references, prompt)|
  missing = references.reject { |path| File.exist?(path) }
  abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt: prompt.join("\n\n"), size: "1K", aspect: "3:4", references:)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
