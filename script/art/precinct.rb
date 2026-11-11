# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내 그림 새로 그리기(docs/M-art-renewal.md, 2026-11-10). 결은 첫 화면과 같은 톤 — 경내 기준 세 장(D3c · 선방 방 넷째 · 천왕문 왼쪽 벽 c)을
# 첫째 참조로. 현판은 비운다(앱이 얹는다). 원본은 tmp/art/ 에만. 고른 뒤에 다음 그림으로 간다.
#   ruby script/art/precinct.rb compound   — 조감도 두 장(1K, 4:3 으로 뽑아 위아래를 잘라 3:2 에 가깝게)
#   ruby script/art/precinct.rb compound2  — 다시 두 장: b 의 가까움과 가운데 축에, 문 셋을 따로 세우고 일주문을 그림 아래 안에
#   ruby script/art/precinct.rb dfix       — d 를 고른 뒤 편집 한 번(다시 뽑지 않음): 미륵 터 · 범종각(a 의 꼴) · 일주문(두 기둥)
#   ruby script/art/precinct.rb dfix-1 …   — 한 번에 셋이 다른 곳까지 많이 바꾸면 하나씩(dfix-maitreya · dfix-bell · dfix-gate)
#   ruby script/art/precinct.rb dfix-bell2 — dfix 에서 범종각만 바뀌지 않았다(2층 난간 누각 그대로). 고친 그림 위에서 범종각 하나만
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

# d 고침 — 첫 참조가 고칠 그림, 나머지는 꼴만. 바꿀 셋 밖은 그대로 둔다.
D_IMAGE = File.join(ART, "compound-d-1.jpeg")
A_BELL = File.join(REFS, "a-bell-pavilion.jpg") # 시안 a 의 범종각을 잘라 세 배로
A_GATE = File.join(REFS, "a-iljumun.jpg")       # 시안 a 의 일주문(두 기둥에 지붕 하나)
DFIX_KEEP = "Change nothing else: keep every other building, the courtyards, the walls, the stone path and steps, every " \
            "pine, the mountains, the mist, the sky, the light, the colors, the ink lines, the hanji texture and the framing " \
            "exactly as they are."
DFIX_MAITREYA = "On the rocky hill at the upper right, there is a small hall standing on the rock ledge. Replace it with an " \
                "open packed-earth yard on top of the rocky hill, enclosed by a low stone wall, the center of the yard left " \
                "completely empty (no statue, no stone, no tree, no lantern in it), and one small hall at the back edge of the " \
                "yard facing it, its front fully open toward the yard and nothing inside it. The sky above the yard is open: no " \
                "trees, roofs or branches in front of the yard or above it."
DFIX_BELL = "On the right side of the courtyard, lower than the rocky hill, there is a bell pavilion. Redraw it in the same " \
            "place and size with the form of the bell pavilion in the second reference: a double-eaved tiled roof over open " \
            "sides on all four sides, no walls, one bronze bell hanging low between the pillars, visible through them."
DFIX_GATE = "Near the bottom of the picture, on the stone path, there is the first gate, drawn now as a pavilion on four " \
            "pillars. Redraw it in the same place and size as a one-pillar gate (iljumun) like the third reference: only two " \
            "pillars standing in one row across the path, one tiled roof resting on them, a blank signboard under the roof " \
            "with nothing written on it, no walls, no back pillars."

D_FIXED = File.join(ART, "compound-d-fix-1.jpeg")
DFIX_BELL2 = "On the right side of the courtyard, lower than the walled yard on the rocky hill, there is a two-storey bell " \
             "pavilion with a railed upper floor and the bell hanging up on that floor. Replace it, in the same place and " \
             "at the same size, with a one-storey open bell pavilion like the second reference: a stone platform, pillars " \
             "on all four sides with no walls and no railing and no upper floor, a double-eaved tiled roof on top, and one " \
             "bronze bell hanging low under the roof, between the pillars, its bottom close to the platform, clearly seen " \
             "through the open sides."

RUNS = {
  "compound" => %w[compound-a compound-b].to_h do |name|
    [ name, [ STANDARD + [ File.join(ART, "aerial-a-1.jpeg"), File.join(REFS, "R30.jpg") ],
              [ COMPOUND_ROLES, COMPOUND, KOREAN_MOUNTAINS, STYLE, FORBIDDEN ] ] ]
  end,
  "compound2" => %w[compound-c compound-d].to_h do |name|
    [ name, [ STANDARD + [ File.join(ART, "compound-b-1.jpeg"), File.join(REFS, "R30.jpg") ],
              [ COMPOUND2_ROLES, COMPOUND2, KOREAN_MOUNTAINS, STYLE, FORBIDDEN ] ] ]
  end,
  "dfix" => { "compound-d-fix" => [ [ D_IMAGE, A_BELL, A_GATE ],
    [ "Edit the first image. The second and third images are only shapes to copy. Make exactly these three changes:",
      "1. #{DFIX_MAITREYA}", "2. #{DFIX_BELL}", "3. #{DFIX_GATE}", DFIX_KEEP, FORBIDDEN ] ] },
  "dfix-bell2" => { "compound-d-fix2" => [ [ D_FIXED, A_BELL ],
    [ "Edit the first image. The second is only a shape to copy.", DFIX_BELL2, DFIX_KEEP, FORBIDDEN ] ] },
  "dfix-maitreya" => { "compound-d-fix-maitreya" => [ [ D_IMAGE ], [ "Edit this image.", DFIX_MAITREYA, DFIX_KEEP, FORBIDDEN ] ] },
  "dfix-bell" => { "compound-d-fix-bell" => [ [ D_IMAGE, A_BELL ],
    [ "Edit the first image. The second is only a shape to copy.", DFIX_BELL, DFIX_KEEP, FORBIDDEN ] ] },
  "dfix-gate" => { "compound-d-fix-gate" => [ [ D_IMAGE, A_GATE ],
    [ "Edit the first image. The second is only a shape to copy.", DFIX_GATE, DFIX_KEEP, FORBIDDEN ] ] }
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
