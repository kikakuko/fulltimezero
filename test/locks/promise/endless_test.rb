# This app is a raft. — 이 앱도 뗏목이다.
#
# 자동 재생도 무한 스크롤도 없다(docs/legal/none.md). 저절로 이어지는 것은 사람을 붙잡는
# 장치다(SPIRIT §1 · §6 — 「하나 더」 유도). 소리와 그림은 사용자가 눌러야 나고, 목록은
# 끝에서 멈춘다. 다음 쪽은 사용자가 고른다.
require "test_helper"

class EndlessTest < ActiveSupport::TestCase
  # 다음 쪽을 부르는 몸짓 — 지켜보다가(IntersectionObserver) 이것을 하면 무한 스크롤이다.
  FETCHING = /\bfetch\(|XMLHttpRequest|Turbo\.visit|renderStreamMessage|\.src\s*=|\.reload\(\)|\bsrc\b.*setAttribute|setAttribute\(\s*["']src/

  test "뷰에 자동 재생이 없다" do
    offenders = Rails.root.glob("app/views/**/*").select { |path| path.file? && path.read.match?(/\bautoplay\b/i) }

    assert_empty relative(offenders), "저절로 재생되는 것이 뷰에 있다"
  end

  test "스크립트가 자동 재생을 켜지 않는다" do
    offenders = Rails.root.glob("app/javascript/**/*.js").select { |path| path.read.match?(/\bautoplay\b/i) }

    assert_empty relative(offenders), "스크립트가 자동 재생을 켠다"
  end

  test "Stimulus 컨트롤러가 IntersectionObserver 로 다음 쪽을 부르지 않는다" do
    offenders = Rails.root.glob("app/javascript/controllers/**/*.js").select do |path|
      source = path.read
      source.include?("IntersectionObserver") && source.match?(FETCHING)
    end

    assert_empty relative(offenders), "스크롤 끝에서 다음 쪽을 저절로 부르는 컨트롤러가 있다"
  end

  test "뷰에 스크롤로 저절로 열리는 틀이 없다" do
    offenders = Rails.root.glob("app/views/**/*").select do |path|
      path.file? && path.read.match?(/turbo[-_]frame[^>\n]*loading[:=]\s*["':]?lazy/)
    end

    assert_empty relative(offenders), "눈에 들면 저절로 다음을 부르는 turbo-frame 이 있다"
  end

  private
    def relative(paths) = paths.map { |path| path.relative_path_from(Rails.root).to_s }
end
