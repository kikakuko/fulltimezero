# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내 그림 새로 그리기(docs/M-art-renewal.md, 2026-11-10). 결은 첫 화면과 같은 톤 — 경내 기준 세 장(D3c · 선방 방 넷째 · 천왕문 왼쪽 벽 c)을
# 첫째 참조로. 현판은 비운다(앱이 얹는다). 원본은 tmp/art/ 에만. 고른 뒤에 다음 그림으로 간다.
#   ruby script/art/precinct.rb compound   — 조감도 두 장(1K, 4:3 으로 뽑아 위아래를 잘라 3:2 에 가깝게)
#   ruby script/art/precinct.rb compound2  — 다시 두 장: b 의 가까움과 가운데 축에, 문 셋을 따로 세우고 일주문을 그림 아래 안에
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
ART = File.join(ROOT, "tmp/art")
REFS = File.join(ART, "refs")
SOURCES = File.join(ROOT, "docs/sources/art")
# 경내 기준 세 장 — 바깥 · 방 · 조상과 단청.
STANDARD = [ File.join(SOURCES, "gate-d3c.jpg"), File.join(SOURCES, "seonbang-room4.jpg"), File.join(SOURCES, "landing-wall-left.jpg") ].freeze

STYLE = "Style: the materials are those of ink painting on hanji — clear ink outlines, the fibers of the hanji visible " \
        "throughout, color laid in flat areas of wash. No photographic texture. But the color and the light are full, not " \
        "washed out, like the first reference: deep green pines, dark tiled roofs, clearly red pillars, warm morning light, " \
        "distinct shadows. The bare white of the paper shows only in sky and mist. Dancheong is muted. No gold anywhere."
FORBIDDEN = "Do not include: gold or gilded color, any writing, letters or signboard calligraphy (leave every signboard " \
            "blank), seals, people, animals, the sun, the moon, elephants, a Maitreya statue, pagodas, modern objects (cars, " \
            "roads with lines, utility poles, wires, signs, lamps, modern buildings), spiky pointed fir or spruce forests, or " \
            "any outer frame or border around the picture."
COMPOUND_ROLES = "Use the references only for these roles: the first three set the color, the values and the materials — " \
                 "match their ink lines, hanji, washes and warm full color (the first for the outdoor colors); the fourth sets " \
                 "the kind of view — the same mountains and temple, but seen much closer; the fifth only shows how the halls of " \
                 "a Korean mountain temple are arranged around courtyards on a slope — do not copy its photographic look."
COMPOUND = "A bird's-eye view, looking obliquely down from a moderate height at a Korean mountain temple nestled on a forested " \
           "mountain slope in morning mist — much closer than the fourth reference, so the temple fills the middle of the " \
           "picture. From the bottom of the picture a stone path climbs straight up the slope through three gates in a line: " \
           "first a one-pillar gate (iljumun) at the forest edge, then a gate hall of the Four Heavenly Kings (cheonwangmun), " \
           "then the gate of non-duality (burimun), opening onto a packed-earth courtyard. At the back of the courtyard, in the " \
           "center, stands the main hall — the largest building, with a deep double-curved tiled roof (the hall of great " \
           "tranquil light). Around the courtyard, smaller halls: on the left a small worship hall and a meditation hall, on " \
           "the right a scripture-copying hall and a small hall on a rock ledge, lower on the left a long sutra-storage hall, " \
           "and lower on the right a two-storey bell pavilion. Rounded Korean ridges rise behind; the upper part of the " \
           "picture is sky and mist. All signboards blank."
KOREAN_MOUNTAINS = "The mountains are Korean: soft rounded ridges layered one behind another, pine trees, and mist between " \
                   "the ridges. No Alpine rock spires."

COMPOUND2_ROLES = "Use the references only for these roles: the first three set the color, the values and the materials — " \
                  "match their ink lines, hanji, washes and warm full color; the fourth sets the distance, the viewpoint and the " \
                  "central axis of the composition — keep them, but fix what is missing in it; the fifth only shows how the halls " \
                  "of a Korean mountain temple are arranged on a slope — do not copy its photographic look."
COMPOUND2 = "A bird's-eye view, looking obliquely down at a Korean mountain temple on a forested slope in morning mist, as close " \
            "as the fourth reference. One straight stone path runs up the central axis from the bottom of the picture to the " \
            "main hall, and on it stand **three separate gates, one above another, each clearly apart**: near the bottom of " \
            "the picture — fully inside the picture, not cut off by the bottom edge — a small one-pillar gate (iljumun: one " \
            "roof on two pillars, no walls) at the edge of the pine forest; above it, after some steps, a gate hall with " \
            "walls on both sides (cheonwangmun); above that, set in the courtyard wall, a third gate (burimun) opening onto " \
            "the packed-earth courtyard. At the back of the courtyard, in the center, the main hall — the largest building, " \
            "deep double-curved tiled roof. Around the courtyard: on the left a small worship hall and a meditation hall, a " \
            "long sutra-storage hall lower on the left; on the right a scripture-copying hall, a small hall on a rock ledge, " \
            "and a two-storey bell pavilion lower on the right. Rounded Korean ridges and mist behind; the upper fifth of the " \
            "picture is sky and mist. All signboards blank."

RUNS = {
  "compound" => %w[compound-a compound-b].to_h do |name|
    [ name, [ STANDARD + [ File.join(ART, "aerial-a-1.jpeg"), File.join(REFS, "R30.jpg") ],
              [ COMPOUND_ROLES, COMPOUND, KOREAN_MOUNTAINS, STYLE, FORBIDDEN ] ] ]
  end,
  "compound2" => %w[compound-c compound-d].to_h do |name|
    [ name, [ STANDARD + [ File.join(ART, "compound-b-1.jpeg"), File.join(REFS, "R30.jpg") ],
              [ COMPOUND2_ROLES, COMPOUND2, KOREAN_MOUNTAINS, STYLE, FORBIDDEN ] ] ]
  end
}.freeze

chosen = RUNS.slice(*ARGV).values.reduce({}, :merge)
abort "부를 것을 고른다: #{RUNS.keys.join(" · ")}" if chosen.empty?
abort "한 번에 #{MonoRouter::MOST_PER_RUN} 장까지" if chosen.size > MonoRouter::MOST_PER_RUN

chosen.each do |name, (references, prompt)|
  missing = references.reject { |path| File.exist?(path) }
  abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt: prompt.join("\n\n"), size: "1K", aspect: "4:3", references:)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
