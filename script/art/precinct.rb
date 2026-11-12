# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내 그림 새로 그리기(docs/M-art-renewal.md, 2026-11-10). 결은 첫 화면과 같은 톤 — 경내 기준 세 장(D3c · 선방 방 넷째 · 천왕문 왼쪽 벽 c)을
# 첫째 참조로. 현판은 비운다(앱이 얹는다). 원본은 tmp/art/ 에만. 고른 뒤에 다음 그림으로 간다.
#   ruby script/art/precinct.rb compound   — 조감도 두 장(1K, 4:3 으로 뽑아 위아래를 잘라 3:2 에 가깝게)
#   ruby script/art/precinct.rb compound2  — 다시 두 장: b 의 가까움과 가운데 축에, 문 셋을 따로 세우고 일주문을 그림 아래 안에
#   ruby script/art/precinct.rb dfix       — d 를 고른 뒤 편집 한 번(다시 뽑지 않음): 미륵 터 · 범종각(a 의 꼴) · 일주문(두 기둥)
#   ruby script/art/precinct.rb dfix-1 …   — 한 번에 셋이 다른 곳까지 많이 바꾸면 하나씩(dfix-maitreya · dfix-bell · dfix-gate)
#   ruby script/art/precinct.rb dfix-bell2 — dfix 에서 범종각만 바뀌지 않았다(2층 난간 누각 그대로). 고친 그림 위에서 범종각 하나만
#   ruby script/art/precinct.rb myojeok    — 묘적광전 안 두 장(1K, 3:4): 빈 연화좌와 빛 · 석조 아미타 · 석조 관세음 · 영가등 · 향
#                                            a 는 영가등이 오른쪽 벽, b 는 왼쪽 벽
#   ruby script/art/precinct.rb myojeok2   — 해인사 대적광전의 짜임(R55 · R54 · R53)을 더 들여 다시 두 장. c 는 영가등이 오른쪽
#                                            격자 장(R54), d 는 왼쪽 천장 아래 줄(R53). b 의 흠(관세음 손의 연기 · 놋쇠빛 향로)을 막는다
#   ruby script/art/precinct.rb cvar       — c 를 고른 뒤 편집 두 판(다시 뽑지 않음): (가) 셋 — 빈 연화좌 · 문수 · 보현,
#                                            (나) 다섯 — 안쪽 문수 · 보현, 바깥 아미타 · 관세음. 둘 다 받침 앞면에 작은 지권인 돋을새김
#   ruby script/art/precinct.rb three-fix  — 셋으로 정한 뒤 (가) 위 편집 한 번: 왼쪽을 문수(보관)로, 받침 돋을새김을 지움,
#                                            오른쪽 벽 영가등 곁에 세로로 긴 아미타내영도 한 폭(먹선 담채). 지권인은 앱이 SVG 로 얹는다
#   ruby script/art/precinct.rb three-fix-1 … — 다른 곳이 많이 바뀌면 하나씩(three-fix-manjushri · three-fix-base · three-fix-amita)
#   ruby script/art/precinct.rb three-fix2 — three-fix 의 탱화에 둥근 광배 선과 작은 낙관이 들어왔다. 그 둘만 지운다
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

# 묘적광전 안(docs/M-beopdang-design.md 3 · 7절). 참조는 장부의 R48(감산사 석조아미타, CC BY 2.0) · R49(조선 관음, CC0 —
# 금박을 입힌 상이라 꼴만) · R50(석굴암, 공공누리 1유형 — 돌의 결만). 셋 다 둥근 광배가 있다 — 광배는 들이지 않는다.
# 통도사 적멸보궁의 「불상 없는 불단」은 「씀」 조건의 안쪽 사진이 없어 글로만 넣는다.
MYOJEOK_ROLES = "Use the references only for these roles: the first three set the color, the values and the materials — match " \
                "their ink lines, hanji, washes and warm full color (the second for the wooden interior, the floor and the light " \
                "through paper windows; the third for carved figures and muted dancheong); the fourth only for the stone, the " \
                "face and the robe of a carved granite Amitabha (seat him instead of standing); the fifth only for the crown and " \
                "the seated posture of a bodhisattva — it is gilded, but ours is plain granite, take no gold from it; the sixth " \
                "only for the grain and the grey of granite and a carved lotus pedestal. The fourth, fifth and sixth all have a " \
                "round or pointed halo behind the figure — do not copy any halo."
MYOJEOK = "Inside a Korean Buddhist hall, seen from the front, from the height of a seated person. Polished wooden floor, " \
          "warm morning light coming in through paper lattice doors. In the foreground, a few empty square sitting cushions " \
          "on the floor, no one on them. At the back, one long low altar platform. **In the center of the altar: a single " \
          "lotus pedestal of pale granite, carefully made and clean, with nothing on it** — an empty seat kept empty on " \
          "purpose, not a missing statue. From high on one side, soft light falls slanting onto the empty lotus pedestal, " \
          "like light from a high window — a slanting shaft of light, not a circle, not a halo, not a ring, not a disc. In " \
          "front of the pedestal, on the altar: one small incense burner and one bowl of clear water. **On the left of the " \
          "altar: a seated granite Amitabha Buddha**, grey stone, calm face, hands in meditation. **On the right: a seated " \
          "granite Avalokitesvara bodhisattva**, grey stone, wearing a crown with one tiny seated Buddha carved in its " \
          "front, holding a slender water bottle (kundika) or a lotus bud. Both figures are plain carved stone, the same " \
          "grey as the pedestal — no gold, no gilding, no paint, no halo or mandorla behind them. The wall behind the altar " \
          "is plain wood and plaster, left empty — no hanging painting. The dancheong on the beams is faint and muted."
MYOJEOK_SIDES = {
  "myojeok-a" => "On the right wall, a few rows of small white paper lanterns hang, softly glowing — no labels, no " \
                 "writing on them. On the left side, a thin line of incense smoke rises faintly.",
  "myojeok-b" => "On the left wall, a few rows of small white paper lanterns hang, softly glowing — no labels, no " \
                 "writing on them. On the right side, a thin line of incense smoke rises faintly."
}.freeze
MYOJEOK_FORBIDDEN = "Do not include: gold or gilded color anywhere, any circle, ring, disc, round halo or mandorla, the sun, " \
                    "the moon, any writing, letters, name tags or signboard calligraphy, seals, people, animals, elephants, " \
                    "pagodas, a hanging Buddhist painting (taenghwa) behind the altar, modern objects (electric lights, " \
                    "cables, signs, donation boxes, plastic), or any outer frame or border around the picture."
MYOJEOK_REFS = STANDARD + %w[R48 R49 R50].map { |label| File.join(REFS, "#{label}.jpg") }

# 해인사 대적광전(R55 · R54 · R53, 2026-11-12) — 짜임만. 그곳은 금빛 삼존 · 큰 탱화 · 원색 단청이라 색은 하나도 들이지 않는다.
MYOJEOK2_ROLES = "Use the references only for these roles: the first three set the color, the values and the materials — " \
                 "match their ink lines, hanji, washes and warm full color (the second for the wooden interior, the floor and " \
                 "the light through paper windows; the third for carved figures and muted dancheong). The fourth (the main hall " \
                 "of Haeinsa) sets the arrangement of the altar only: one long carved altar platform (sumidan) across the back, " \
                 "a carved wooden canopy above it, three seats in a row with the center one raised highest, a low offering " \
                 "table in front and the open wooden floor. Take none of its colors: no gold statues, no hanging paintings, no " \
                 "bright paint. The fifth sets only the form of the lamps on the side — take neither its colors nor any " \
                 "writing. The sixth is only the stone and the face of a granite Amitabha (seat him); the seventh only the " \
                 "crown and the posture of a bodhisattva — it is gilded, ours is plain granite. Do not copy any halo from any " \
                 "reference."
MYOJEOK2 = "Inside a Korean Buddhist main hall, seen from the front and the center, from the height of a seated person, like " \
           "the fourth reference but calm and plain. Polished wooden floor, warm morning light through paper lattice doors. In " \
           "the foreground, a few empty square sitting cushions, no one on them. Across the back, one long low altar platform " \
           "of dark wood with softly carved panels, and above its center a carved wooden canopy, unpainted or faintly painted. " \
           "**In the center of the altar, raised one step higher than the two sides: a single lotus pedestal of pale granite, " \
           "carefully made and clean, with nothing on it** — a seat kept empty on purpose, the most honored place in the " \
           "hall, not a missing statue. A shaft of soft light falls slanting from a high window straight onto the empty lotus " \
           "pedestal — a slanting shaft, not a circle, not a halo, not a ring, not a disc. In front of the altar, on a low " \
           "offering table: one small incense burner of dark iron (black, not brass, not gold) with a thin line of smoke " \
           "rising from it, and one white bowl of clear water. **On the left seat: a seated granite Amitabha Buddha**, grey " \
           "stone, calm face, hands in meditation. **On the right seat: a seated granite Avalokitesvara bodhisattva**, grey " \
           "stone, a crown with one tiny seated Buddha carved in its front, **holding a slender water bottle (kundika) in one " \
           "hand** — nothing burning, no smoke from the hands. Both figures are plain carved stone — no gold, no gilding, no " \
           "paint, no halo behind them. The wall behind the altar is plain wood and plaster, left empty — no hanging painting. " \
           "The dancheong on the beams is faint and muted."
MYOJEOK2_SIDES = {
  "myojeok-c" => [ File.join(REFS, "R54.jpg"), "On the right side wall, a tall wooden cabinet of small square niches in a grid, " \
                   "like the fifth reference, and in each niche a small white paper lamp softly glowing — no labels, no " \
                   "tablets, no writing." ],
  "myojeok-d" => [ File.join(REFS, "R53.jpg"), "On the left side, under the ceiling beams, several rows of small white paper " \
                   "lanterns hang close together, like the rows in the fifth reference but all white and softly glowing — no " \
                   "labels, no tags, no writing." ]
}.freeze

# c 고침(2026-11-12) — 해인사 대적광전 비로자나삼존(문수 · 보현이 연꽃 가지)의 짜임. 지권인은 R57(통일신라 석조, CC0)의 손:
# 세운 왼손 검지를 오른손이 감싸 쥔다(『한국민족문화대백과』 「비로자나불화」). 보현의 코끼리 · 문수의 사자는 그리지 않는다.
C_IMAGE = File.join(ART, "myojeok-c-1.jpeg")
JIGWON = File.join(REFS, "R57-hands.jpg")      # R57 의 손을 잘라 두 배로
ATTENDANT = File.join(REFS, "R55-attendant.jpg") # R55 의 왼쪽 협시를 잘라 두 배로 — 꼴만
CVAR_REFS = "Edit the first image. The second image is only the shape of a hand gesture to carve; the third is only the " \
            "seated posture and the long lotus branch of a bodhisattva — take none of its gold, red or bright colors."
BODHISATTVAS = "a seated granite bodhisattva Manjushri and a seated granite bodhisattva Samantabhadra, each wearing a " \
               "simple carved crown and holding one long lotus branch with a bud, like the third image, the two mirror " \
               "each other; no animal mounts — no lion, no elephant"
JIGWON_RELIEF = "On the front face of the stone base under the empty lotus pedestal, carve one small low relief, about the " \
                "size of a palm, of two hands in this gesture, like the second image: the left index finger raised and " \
                "the right hand wrapped around it — the same grey granite as the base, no paint, no gold, no circle around it."
CVAR_KEEP = "Keep exactly as they are: the empty lotus pedestal in the center and the slanting shaft of light, the carved " \
            "wooden canopy, the long carved altar, the right wall with its grid of white lamps, the dark iron incense burner " \
            "with its thin smoke and the bowl of clear water, the floor, the cushions, the open door and the pine outside, the " \
            "colors, the ink lines and the hanji texture. The wall behind the altar stays empty — nothing painted or hung on " \
            "it. No circles, halos or mandorlas anywhere. No gold anywhere."
CVAR = {
  "myojeok-c-three" => "Replace the two seated figures on the altar — the Amitabha on the left and the Avalokitesvara on the " \
                       "right — with #{BODHISATTVAS}: Manjushri on the left seat, Samantabhadra on the right seat. Three seats " \
                       "in all: the empty lotus pedestal in the middle and the two bodhisattvas.",
  "myojeok-c-five" => "Make five seats on the same altar. Keep the empty lotus pedestal in the middle. Right beside it, on the " \
                      "inner seats, place #{BODHISATTVAS}: Manjushri on the inner left, Samantabhadra on the inner right. On " \
                      "the outer ends, keep the seated granite Amitabha Buddha (far left) and the seated granite " \
                      "Avalokitesvara with the water bottle (far right), made a little smaller so that all five fit on the " \
                      "altar without crowding."
}.freeze

# 셋으로 정함(2026-11-12) — 다섯은 접었다. 아미타불은 불단이 아니라 오른쪽 벽의 탱화(아미타내영도 — 『관무량수경』 상품중생
# 「是故我今來迎接汝」 T12n0365 p0345a08–a11). 꼴의 참조는 R61(기메 소장 고려 아미타여래도, 퍼블릭 도메인) — 광배 · 적색 · 금빛은 들이지 않는다.
THREE_IMAGE = File.join(ART, "myojeok-c-three-1.jpeg")
AMITA_REF = File.join(REFS, "R61.jpg")
THREE_KEEP = "Change nothing else: keep the right bodhisattva, the empty lotus pedestal and the slanting shaft of light, the " \
             "carved canopy, the long altar, the grid of white lamps, the incense burner and its smoke, the bowl of water, " \
             "the floor, the cushions, the open door and the pine, the colors, the ink lines and the hanji texture exactly " \
             "as they are. The wall panel behind the empty lotus pedestal stays empty. No circles, halos or mandorlas. No gold."
THREE_MANJUSHRI = "The seated stone figure on the left of the altar has the head of a Buddha (a bun of curls on the head). " \
                  "Change it into the bodhisattva Manjushri: a seated granite bodhisattva wearing a carved crown like the one " \
                  "on the right figure, holding one long lotus branch, a mirror image of the right figure so the two make a " \
                  "pair — plain grey stone, no gold, no animal."
THREE_BASE = "On the front of the stone base under the empty lotus pedestal there is a small carved mark. Remove it: the " \
             "front of the base is smooth plain granite, as it was before."
THREE_AMITA = "On the right wall, beside the grid of white lamps (above it or next to it, without covering any lamp), hang " \
              "one tall narrow hanging scroll painting of Amitabha Buddha coming to welcome: Amitabha standing, turned a " \
              "little, one hand reaching down, in the posture of the second image. Paint it in fine ink lines with very " \
              "light washes, almost a line drawing on pale silk — no deep red, no green, no gold, no halo or circle " \
              "behind the head, no writing, no seals, no other figures. A simple wooden roller at top and bottom."

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
  "myojeok" => MYOJEOK_SIDES.to_h do |name, side|
    [ name, [ MYOJEOK_REFS, [ MYOJEOK_ROLES, MYOJEOK, side, STYLE, MYOJEOK_FORBIDDEN ] ] ]
  end,
  "myojeok2" => MYOJEOK2_SIDES.to_h do |name, (lamp_ref, side)|
    [ name, [ STANDARD + [ File.join(REFS, "R55.jpg"), lamp_ref, File.join(REFS, "R48.jpg"), File.join(REFS, "R49.jpg") ],
              [ MYOJEOK2_ROLES, MYOJEOK2, side, STYLE, MYOJEOK_FORBIDDEN ] ] ]
  end,
  "cvar" => CVAR.to_h do |name, change|
    [ name, [ [ C_IMAGE, JIGWON, ATTENDANT ], [ CVAR_REFS, change, JIGWON_RELIEF, CVAR_KEEP, MYOJEOK_FORBIDDEN ] ] ]
  end,
  "three-fix" => { "myojeok-three-fix" => [ [ THREE_IMAGE, AMITA_REF ],
    [ "Edit the first image. The second image is only the posture of a figure to paint on a scroll — take none of its " \
      "colors, its halo or its gold. Make exactly these three changes:",
      "1. #{THREE_MANJUSHRI}", "2. #{THREE_BASE}", "3. #{THREE_AMITA}", THREE_KEEP, MYOJEOK_FORBIDDEN ] ] },
  "three-fix-manjushri" => { "myojeok-three-fix-m" => [ [ THREE_IMAGE ], [ "Edit this image.", THREE_MANJUSHRI, THREE_KEEP, MYOJEOK_FORBIDDEN ] ] },
  "three-fix-base" => { "myojeok-three-fix-b" => [ [ THREE_IMAGE ], [ "Edit this image.", THREE_BASE, THREE_KEEP, MYOJEOK_FORBIDDEN ] ] },
  "three-fix-amita" => { "myojeok-three-fix-a" => [ [ THREE_IMAGE, AMITA_REF ],
    [ "Edit the first image. The second is only a posture to copy.", THREE_AMITA, THREE_KEEP, MYOJEOK_FORBIDDEN ] ] },
  "three-fix2" => { "myojeok-three-fix2" => [ [ File.join(ART, "myojeok-three-fix-1.jpeg") ],
    [ "Edit this image. On the right wall, in the tall hanging scroll of the standing Buddha, there is a thin round circle " \
      "drawn behind the Buddha's head, and a small square seal mark in the lower right corner of the painting. Remove " \
      "both: no circle behind the head, no seal — only plain pale silk there. Keep the Buddha's figure, its ink lines and " \
      "everything else in the whole image exactly as it is.", MYOJEOK_FORBIDDEN ] ] },
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

  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt: prompt.join("\n\n"), size: "1K", aspect: name.start_with?("myojeok") ? "3:4" : "4:3", references:)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
