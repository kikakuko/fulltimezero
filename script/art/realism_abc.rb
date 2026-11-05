# This app is a raft. — 이 앱도 뗏목이다.
#
# 세 결 시안 — 일주문 하나를 같은 구도, 같은 참조로 세 결에 그린다. 고르는 것은 사람이다.
# 참조는 셋 다 같다: R22(부석사 일주문, CC0 — docs/art-sources.md)와 우리 그림 둘(산수 · 미륵당).
# 1K · 3:4 · 한 장씩. 원본은 tmp/art/ 에만.
#   ruby script/art/realism_abc.rb          — 셋 다
#   ruby script/art/realism_abc.rb a c      — 고른 것만
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
ROOT = MonoRouter::ROOT
REFERENCES = [
  File.join(ROOT, "tmp/art/refs/R22.jpg"),
  File.join(ROOT, "app/assets/images/elephant_field.webp"),
  File.join(ROOT, "app/assets/images/mireukdang.webp")
].freeze

COMPOSITION = "Early morning at the end of a forest path. A Korean temple one-pillar gate (iljumun) stands squarely " \
              "in the center, seen straight on; beyond the gate the path continues on into the trees. " \
              "Use the first reference only for the gate's structure and proportions; use the other two only for the " \
              "overall mood and palette of the app."
FORBIDDEN = "Do not include: moon, sun, people, animals, any writing or letters, signboard calligraphy (leave the " \
            "signboard blank or omit it), seals, modern objects (signs, fences, lamps, cars, wires), or any frame or border."

STYLES = {
  "a" => [ "realism-a-ink", "Style: realistic ink-and-wash painting. Building proportions, perspective and light are " \
                            "accurate, but the medium is ink and light washes of color on hanji paper. Dancheong colors " \
                            "are subdued into pale washes." ],
  "b" => [ "realism-b-painterly", "Style: photorealistic painting. Light and material feel real, with a few brush marks " \
                                  "left visible, like a painting rather than a photograph." ],
  "c" => [ "realism-c-photo", "Style: realistic photograph, as if a real temple was photographed in morning mist." ]
}.freeze

missing = REFERENCES.reject { |path| File.exist?(path) }
abort "참조가 없다: #{missing.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}" if missing.any?

chosen = ARGV.any? ? STYLES.slice(*ARGV) : STYLES
abort "한 번에 #{MonoRouter::MOST_PER_RUN} 장까지" if chosen.size > MonoRouter::MOST_PER_RUN

chosen.each_value do |name, style|
  prompt = [ COMPOSITION, style, FORBIDDEN ].join("\n\n")
  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt:, size: "1K", aspect: "3:4", references: REFERENCES)
  puts "#{name}: #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
