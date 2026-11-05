# This app is a raft. — 이 앱도 뗏목이다.
#
# 연결 확인(그림 도구 1단계). 셋을 한 장씩 부른다 — 참조 없이, 참조 하나, 참조 넷.
# 한 번 실행에 넷을 넘기지 않는다(MonoRouter::MOST_PER_RUN). 원본은 tmp/art/ 에만.
#   ruby script/art/connection_check.rb          — 셋 다
#   ruby script/art/connection_check.rb b c      — 고른 것만(a · b · c)
require_relative "monorouter"

MODEL = "gemini-3-pro-image"
IMAGES = File.join(MonoRouter::ROOT, "app/assets/images")
CIRCLE = "한지 위에 먹으로 그린 빈 원 하나. 글자 없음."

runs = [
  [ "check-a-none", CIRCLE, [] ],
  [ "check-b-one", "이 그림과 같은 결로 빈 원 하나. 글자 없음.", [ "mireukdang.webp" ] ],
  [ "check-c-four", "이 그림들과 같은 결로 빈 원 하나. 글자 없음.", %w[mireukdang.webp compound.webp gates.webp elephant_field.webp] ]
]
runs.select! { |name, _, _| ARGV.include?(name[/check-(\w)-/, 1]) } if ARGV.any?
raise "한 번에 #{MonoRouter::MOST_PER_RUN} 장까지" if runs.size > MonoRouter::MOST_PER_RUN

runs.each do |name, prompt, references|
  paths, spent = MonoRouter.draw(name:, model: MODEL, prompt:, size: "1K", references: references.map { |f| File.join(IMAGES, f) })
  puts "#{name}: 참조 #{references.size} · #{spent} 크레딧 · #{paths.map { |p| p.delete_prefix("#{MonoRouter::ROOT}/") }.join(", ")}"
rescue MonoRouter::Error => e
  puts "#{name}: 참조 #{references.size} · 실패 — #{e.message}"
  break if e.message.start_with?("예산에 닿았다")
end
puts "이 키의 used_credits 누계: #{MonoRouter.used} / #{MonoRouter::BUDGET}"
