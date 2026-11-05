# This app is a raft. — 이 앱도 뗏목이다.
#
# B 결 시험 — 선방, 앉은 코끼리. 1K · 3:4 · 한 장. 고르는 것은 사람이다.
# 참조 넷: B 시안(결의 기준) · 선방 산수 elephant_field.webp(구도의 기준) · docs/drawings/elephant_sitting.png
# (앉은 자세) · R03 정선 〈개화사〉(산의 생김, 퍼블릭 도메인 — docs/art-sources.md). 원본은 tmp/art/ 에만.
#   ruby script/art/seonbang_b.rb
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
REFERENCES = [
  File.join(ROOT, "tmp/art/realism-b-painterly-1.jpeg"),
  File.join(ROOT, "app/assets/images/elephant_field.webp"),
  File.join(ROOT, "docs/drawings/elephant_sitting.png"),
  File.join(ROOT, "tmp/art/refs/R03.jpg")
].freeze

ROLES = "Use the references only for these roles: the first for the rendering (light, materials, color); the second " \
        "for the composition (a rock at the bottom, a path winding upward through the mountains); the third only for " \
        "the elephant's seated pose; the fourth only for the shapes of the mountains."
COMPOSITION = "A valley high in the mountains. Lower in the picture, on a broad flat rock by the side of the path, a " \
              "single Asian elephant sits quietly in profile, facing left. Its haunches rest on the rock and its front " \
              "legs stand upright; its eyes are closed and its trunk hangs relaxed. Its skin is dark grey. Behind the " \
              "rock a dirt path winds back and forth up along the mountains and disappears into the mist. Leave the " \
              "upper third of the picture empty with sky and mist."
STYLE = "Style: the same photorealistic painting as the first reference. Early morning light slanting in, mist, " \
        "convincing textures, only a few visible brush marks."
FORBIDDEN = "Do not include: moon, sun, people, any other animals, any writing or letters, seals, any frame or border, " \
            "or modern objects. No decoration, harness or saddle on the elephant. No named stones or markers by the path."

missing = REFERENCES.reject { |path| File.exist?(path) }
abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

prompt = [ ROLES, COMPOSITION, STYLE, FORBIDDEN ].join("\n\n")
begin
  paths, spent = MonoRouter.draw(name: "seonbang-b", model: MODEL, prompt:, size: "1K", aspect: "3:4", references: REFERENCES)
  puts "seonbang-b: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "seonbang-b: 실패 — #{e.message}"
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
