# This app is a raft. — 이 앱도 뗏목이다.
#
# 글꼴. 한글 명조는 가로획이 가늘어 작은 크기에서 먼저 사라진다.
# 명조는 짧고 큰 글(18px 이상)에만, 읽는 글은 모두 고딕이다.
require "test_helper"

class TypeTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  SERIF_FLOOR = 18

  TOKENS = {
    voice: "400 1.5rem/1.6 var(--serif)",
    title: "700 1.25rem/1.5 var(--serif)",
    body: "400 0.9375rem/1.7 var(--sans)",
    ui: "400 0.9375rem/1.4 var(--sans)",
    label: "400 0.75rem/1.5 var(--sans)"
  }.freeze

  # 읽는 글 — 카드의 한 줄, 방 머리의 한 줄, 선방의 한 줄, 안내의 본문과 인용,
  # 아홉 자리의 설명, 사경의 글자 풀이.
  READING = [ ".compound__card-line", ".hall-header__line", ".quote",
              ".guide > p:not(.lead):not(.aside), .guide blockquote p", ".copy-notes dd" ].freeze

  # 옅은 --mute 가 설 수 있는 자리 — 출전 · 한자 곁말 · 닫는 손잡이 같은 보조.
  MUTE_PLACES = %w[.threshold__source .compound__card-source .guide\ .source .compound__card-han .compound__card-close].freeze

  test "글꼴 다섯은 :root 의 토큰이다" do
    root = css[/:root \{.*?\n\}/m]

    TOKENS.each { |name, value| assert_match(/--type-#{name}: #{Regexp.escape(value)};/, root) }
    assert_match(/--serif: "Noto Serif KR",/, root)
    assert_match(/--sans: "Noto Sans KR",/, root)
    assert_match(/--ink-soft: #4a524f;/, root)
  end

  test "명조는 18px 이상에만 쓴다" do
    serif_classes = []

    rules.each do |selector, body|
      next unless serif?(body)

      size = size_of(body)
      assert size, "명조의 크기가 정해지지 않았다(물려받으면 작아진다): #{selector}"
      assert_operator size, :>=, SERIF_FLOOR, "#{SERIF_FLOOR}px 보다 작은 명조: #{selector} (#{size}px)"
      serif_classes.concat(selector.scan(/\.[\w-]+/).last(1))
    end

    # 명조인 자리를 다른 규칙이 작게 덮어쓰는 것도 같다.
    rules.each do |selector, body|
      next if serif?(body) || !(size = size_of(body))
      next unless size < SERIF_FLOOR && body.match?(/font(?:-size)?:/)

      target = selector.gsub(/:not\([^)]*\)/, "")
      hit = serif_classes.uniq.find { |name| target.match?(/#{Regexp.escape(name)}(?![\w-])/) }
      assert_nil hit, "#{hit} 의 명조를 #{selector} 가 #{size}px 로 줄인다"
    end
  end

  test "읽는 글은 고딕 본문이고 색은 --ink-soft 다" do
    READING.each do |selector|
      body = rules.find { |one, _| one == selector }&.last
      assert body, "#{selector} 규칙이 없다"
      assert_match(/font: var\(--type-body\)/, body, "#{selector} 가 고딕 본문이 아니다")
      assert_match(/(?<![-\w])color: var\(--ink-soft\)/, body, "#{selector} 의 색이 --ink-soft 가 아니다")
    end
  end

  test "--mute 는 보조에만 쓴다" do
    rules.each do |selector, body|
      next unless body.match?(/(?<![-\w])color: var\(--mute\)/)

      assert_includes MUTE_PLACES, selector, "읽는 글이 --mute 로 흐리다: #{selector}"
    end
  end

  test "손잡이 — 버튼은 고딕이다" do
    %w[.action button,\ input[type="submit"]].each do |selector|
      body = rules.find { |one, _| one == selector }&.last
      assert_match(/font: var\(--type-ui\)/, body, "#{selector} 가 고딕 손잡이가 아니다")
    end
  end

  private
    def css = CSS.read

    def rules
      @rules ||= css.gsub(%r{/\*.*?\*/}m, "").sub(/:root \{.*?\n\}/m, "")
                    .scan(/([^{}@]+)\{([^{}]*)\}/).map { |selector, body| [ selector.split.join(" "), body ] }
    end

    def serif?(body)
      body.match?(/font-family: var\(--serif\)|font: [^;]*var\(--serif\)|font: var\(--type-(?:voice|title)\)/)
    end

    def size_of(body)
      token = body[/font: var\(--type-(\w+)\)/, 1]
      value = token ? TOKENS.fetch(token.to_sym)[/ ([\d.]+(?:rem|px))/, 1] : body[/font(?:-size)?: (?:\d{3} )?([\d.]+(?:rem|px))/, 1]
      return unless value

      value.end_with?("rem") ? value.to_f * 16 : value.to_f
    end
end
