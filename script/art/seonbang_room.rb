# This app is a raft. — 이 앱도 뗏목이다.
#
# 선방 방 시안 — 몸이 앉는 자리(docs/M-seonbang-room-design.md). 결은 D(docs/art-style.md, 기준 D3a).
# 정면 벽의 족자 틀 안은 빈 한지 — 거기에 지금의 산수와 코끼리를 앱이 끼운다. 틀 안에 그림이 그려지면 실패다.
# 1K · 3:4 · 두 장. 원본은 tmp/art/ 에만.
#   ruby script/art/seonbang_room.rb          — 첫 시안(2026-11-05, 족자가 작고 멀다)
#   ruby script/art/seonbang_room.rb 2        — 둘째 시안(족자를 크고 가깝게, 장황에 금빛 없이)
#   ruby script/art/seonbang_room.rb 3        — 셋째 시안(둘째 B 를 기준으로 족자 안을 세로 0.73, 장황은 옅게) 한 장
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
SECOND = ARGV.include?("2")
THIRD = ARGV.include?("3")
REFERENCES = [
  File.join(ROOT, "docs/sources/art/gate-d3a.jpg"),
  File.join(ROOT, "tmp/art/realism-a-ink-1.jpeg"),
  File.join(ROOT, "app/assets/images/mireukdang.webp")
].freeze

ROLES = "Use the references only for the medium and style — clear ink outlines on hanji paper, flat areas of pale " \
        "wash, visible hanji fibers. Do not copy their subjects or composition."
ROOM = "The inside of a Korean Buddhist meditation hall (seonwon), seen straight on from the back of the room. A plain " \
       "wooden maru floor. Pale morning light comes in softly through paper-covered lattice doors (changhoji) at the " \
       "sides; the paper glows but nothing outside is visible through it. Several low square meditation cushions " \
       "(jwabok) are laid out in neat rows on the floor, all of them empty. On the front wall, in the center, hangs a " \
       "tall narrow vertical hanging-scroll frame (jokja) with a mounted border, and the inside of the frame is " \
       "completely blank hanji paper — leave it empty, do not paint anything inside it. Quiet, spacious, nearly empty."
STYLE = "Style: clear ink outlines on hanji paper, flat areas of pale wash, the fibers of the hanji visible throughout. " \
        "Even the morning light is rendered as soft bleeding of ink and wash. No photographic texture. Dancheong colors, " \
        "if any, are subdued into pale washes."
FORBIDDEN = "Do not include: people, the moon, the sun, elephants, a Maitreya statue, pagodas, Buddha statues, animals, " \
            "any writing or letters, calligraphy, seals, any scenery visible through windows or doors, modern objects " \
            "(cars, utility poles, wires, signboards, signs, lamps, modern buildings), or any outer frame or border " \
            "around the picture. Nothing painted inside the hanging-scroll frame."

# 둘째 시안 — 족자를 크고 가깝게. 족자 안 빈 한지가 화면 폭의 절반 넘게, 세로는 40% 넘게, 비율은 산수(864×1184)에
# 가깝게. 장황은 옅은 쪽빛이나 한지빛, 금빛은 없다(§2 — 금빛은 탑의 한 자에만). 첫 시안 B 를 꼴의 참조로 넣는다.
ROOM2 = "The inside of a Korean Buddhist meditation hall (seonwon), seen straight on, standing close to the front wall. " \
        "A plain wooden maru floor in the lower part of the picture with several low square meditation cushions " \
        "(jwabok) in rows, all of them empty. Pale morning light comes softly through paper-covered lattice doors at the " \
        "sides; nothing outside is visible. The front wall is dominated by one large Korean hanging scroll (jokja) with " \
        "a wooden roller (chuk) at the bottom and two narrow hanging strips (pungdae) at the top. The scroll is big and " \
        "close: the blank picture area inside its mounting is more than half the width of the whole image and more than " \
        "40 percent of its height, with proportions of about 3 wide by 4 tall. The mounting silk is pale indigo or the " \
        "color of plain hanji — no gold, no gilded or yellow-gold trim anywhere. The picture area inside the mounting is " \
        "completely blank hanji paper — leave it empty, do not paint anything inside it."
ROLES2 = "Use the first two references only for the medium and style (ink outlines on hanji, pale washes). Use the third " \
         "reference only for the kind of room and the form of the Korean hanging scroll — make the scroll much larger " \
         "and closer than in it, and change its mounting color. Do not copy the third reference's gold trim."
FORBIDDEN2 = FORBIDDEN + " No gold or gilded color anywhere in the picture."

# 셋째 시안 — 둘째 B 의 방 그대로. 족자 안 빈 한지를 세로로 긴 꼴(가로:세로 0.73 — 지금 산수 864×1184 와 같다)로,
# 폭은 화면의 45% 안팎 · 세로 60% 안팎. 족자는 천장 가까이에서 내려와 좌복 줄 바로 위에서 끝난다. 장황은 옅은 회청이나
# 한지빛 — 산수보다 먼저 눈에 띄지 않게. 금빛은 없다.
ROOM3 = "Keep the same room, viewpoint and composition as the first reference: a Korean meditation hall seen straight on, " \
        "paper-covered lattice doors at the sides with pale morning light, a wooden floor with rows of empty low " \
        "square cushions. Change only the hanging scroll on the front wall: it hangs from near the ceiling and ends just " \
        "above the first row of cushions. The blank picture area inside its mounting is a tall upright rectangle with " \
        "width to height of 0.73 (like 864 by 1184) — about 45 percent of the image width and about 60 percent of the " \
        "image height. The mounting silk is a very pale grey-blue or the color of plain hanji, quiet and low in contrast, " \
        "so that it does not draw the eye before the picture area. No gold anywhere. The picture area is completely blank " \
        "hanji paper — leave it empty, do not paint anything inside it."
ROLES3 = "Use the first reference for the room and composition. Use the second reference only for the medium and style " \
         "(clear ink outlines on hanji, flat pale washes, visible hanji fibers)."

room, roles, forbidden, names, references =
  if THIRD
    [ ROOM3, ROLES3, FORBIDDEN2, %w[seonbang-room3],
      [ File.join(ROOT, "tmp/art/seonbang-room2-b-1.jpeg"), REFERENCES.first ] ]
  elsif SECOND
    [ ROOM2, ROLES2, FORBIDDEN2, %w[seonbang-room2-a seonbang-room2-b],
      REFERENCES.first(2) + [ File.join(ROOT, "tmp/art/seonbang-room-b-1.jpeg") ] ]
  else
    [ ROOM, ROLES, FORBIDDEN, %w[seonbang-room-a seonbang-room-b], REFERENCES ]
  end
missing = references.reject { |path| File.exist?(path) }
abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

prompt = [ roles, room, STYLE, forbidden ].join("\n\n")
names.each do |name|
  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt:, size: "1K", aspect: "3:4", references:)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
