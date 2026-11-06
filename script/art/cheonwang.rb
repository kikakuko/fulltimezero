# This app is a raft. — 이 앱도 뗏목이다.
#
# 천왕문 시안 — 둘째 문 안 양쪽 벽의 사천왕(docs/M-landing-design.md, 고증은 같은 문서 4절). 결은 D(docs/art-style.md,
# 기준 D3a). 짜임은 통도사 천왕문 그대로:
#   왼쪽 벽(들어서며 왼쪽, 벽을 마주 보면) — 왼쪽에 용과 여의주, 오른쪽에 탑과 당.
#   오른쪽 벽(들어서며 오른쪽, 벽을 마주 보면) — 왼쪽에 비파, 오른쪽에 칼.
# 책은 사천왕의 지물이 아니라 들이지 않는다. 얼굴은 위엄 있되 무섭지 않게 — 쉬러 들어오는 사람을 지키는 얼굴.
# 1K · 3:4 · 벽마다 두 장(넷). 원본은 tmp/art/ 에만.
#   ruby script/art/cheonwang.rb
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
REFERENCES = [
  File.join(ROOT, "docs/sources/art/gate-d3a.jpg"),          # 결 — D3a
  File.join(ROOT, "docs/sources/art/seonbang-room.jpg"),     # 결 — 선방 방(문 안의 실내, 같은 결)
  File.join(ROOT, "tmp/art/refs/R23.jpg"),                   # 짜임 — 통도사 천왕문 안, 용 · 탑과 당
  File.join(ROOT, "tmp/art/refs/R47.jpg"),                   # 짜임 — 통도사 천왕문 안, 칼
  File.join(ROOT, "tmp/art/refs/R43.jpg")                    # 짜임 — 통도사 천왕문(바깥, 유리건판)
].freeze

ROLES = "Use the first two references only for the medium and style: clear ink outlines on hanji paper, flat areas of " \
        "pale wash, visible hanji fibers. Use the third and fourth references only for what the Korean Four Heavenly " \
        "Kings of Tongdosa temple look like and what they hold — their tall flower-and-flame crowns, round eyes, beards, " \
        "patterned armor and long sashes rising behind the shoulders — but do NOT copy their saturated colors or their " \
        "fierce bulging expressions. Use the fifth reference only for the kind of building: a Korean Joseon-dynasty " \
        "three-bay gate hall with plain wooden pillars."
SCENE = "Inside the Cheonwangmun (Heavenly Kings Gate) of a Korean Buddhist mountain temple, seen straight on from the " \
        "central passage, facing one side wall. Behind a low plain wooden rail, two of the Four Heavenly Kings sit side " \
        "by side as large painted wooden statues, filling most of the picture, in the Korean late-Joseon manner (not " \
        "Chinese, not Japanese). Their feet rest on low plain rocks. Their faces are dignified and calm, with a steady " \
        "watchful gaze and a closed, gentle mouth — protective, not frightening: they guard the people who come in to rest. " \
        "Above them, the plain rafters and beams of the gate hall; at the side, a small latticed window glowing softly " \
        "with morning light."
KINGS = {
  left: "The king on the left holds a long Korean dragon coiling around one arm and holds up a small round jewel (a " \
        "wish-fulfilling pearl) between the fingers of the other hand. The king on the right holds a long pole with a " \
        "narrow hanging banner (dang) in one hand and raises a small multi-storied pagoda on the palm of the other hand.",
  right: "The king on the left holds a bipa (a Korean pear-shaped four-string lute) across his body and plucks it. The " \
         "king on the right holds a straight sword diagonally across his chest, the other hand resting on his hip."
}.freeze
STYLE = "Style: clear ink outlines on hanji paper, flat areas of pale wash, the fibers of the hanji visible throughout. " \
        "The dancheong colors of the statues and the hall are subdued into pale washes — soft blue-green, pale red, ochre — " \
        "never saturated. No photographic texture at all — no photographic depth of field, grain or realistic materials."
FORBIDDEN = "Do not include: gold or gilded color anywhere, books or scrolls in any hand, any writing, letters, signboards, " \
            "name plates, calligraphy or seals, people, trampled demons or small figures under the feet, the sun, the " \
            "moon, elephants, animals other than the one dragon, Chinese door gods, Chinese red lanterns, modern objects " \
            "(lamps, signs, wires, fences of metal), or any outer frame or border around the picture."

missing = REFERENCES.reject { |path| File.exist?(path) }
abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

%w[a b].product(%i[left right]).sort_by { |_, side| side }.each do |take, side|
  name = "cheonwang-#{side}-#{take}"
  prompt = [ ROLES, SCENE, KINGS.fetch(side), STYLE, FORBIDDEN ].join("\n\n")
  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt:, size: "1K", aspect: "3:4", references: REFERENCES)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
