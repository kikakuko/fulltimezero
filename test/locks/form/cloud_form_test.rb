# This app is a raft. — 이 앱도 뗏목이다.
#
# 구름의 결 — 짙기 셋과 빠르기 셋, 그리고 떠가는 방법.
# 「도상 뒤에 선다」는 약속 쪽이다(test/locks/promise/cloud_test.rb).
# 「먼 것이 느리다」는 성질이라 기능 쪽이다(test/models/cloud_depth_test.rb).
require "test_helper"

class CloudFormTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  test "짙기와 빠르기는 :root 의 여섯 값이다" do
    root = css[/:root \{.*?\n\}/m]

    { "far" => "0.38", "mid" => "0.46", "near" => "0.54" }.each do |depth, value|
      assert_match(/--cloud-#{depth}: #{Regexp.escape(value)};/, root, "구름의 짙기(#{depth})가 바뀌었다")
    end
    { "far" => "310s", "mid" => "240s", "near" => "180s" }.each do |depth, value|
      assert_match(/--cloud-span-#{depth}: #{value};/, root, "구름의 빠르기(#{depth})가 바뀌었다")
    end
  end

  # 자리는 옮길 수 있다. 다만 세 그림이 저마다 다른 깊이를 쓰는 것은 그대로다.
  test "구름 셋이 저마다 다른 깊이를 쓴다" do
    { "mist" => "far", "drift" => "mid", "scroll" => "near" }.each do |name, depth|
      rule = css[/\.cloud--#{name} \{.*?\n\}/m].to_s

      assert_match(/background-image: url\("cloud-#{name}\.webp"\)/, rule, "#{name} 의 그림이 바뀌었다")
      assert_match(/opacity: var\(--cloud-#{depth}\)/, rule, "#{name} 이 제 깊이의 짙기를 쓰지 않는다")
      assert_match(/--cloud-span: var\(--cloud-span-#{depth}\)/, rule, "#{name} 이 제 깊이의 빠르기를 쓰지 않는다")
    end
  end

  test "떠가는 것은 transform 뿐이다 — 자리는 건드리지 않는다" do
    frames = css[/@keyframes cloud-drift \{.*?\n\}/m].to_s

    assert_match(/transform: translate3d\(/, frames)
    assert_no_match(/(?:^|\s)(?:left|top|right|bottom|margin|background-position):/, frames,
      "떠가는 데 자리를 쓴다 — transform 만 움직인다")
  end

  test "움직임을 끈 사람에게는 멈춘 채로 보인다 — 사라지지 않는다" do
    rule = css[/@media \(prefers-reduced-motion: reduce\) \{\s*\n\s*\.cloud \{[^}]*\}/m].to_s

    assert_match(/animation-play-state: paused/, rule, "구름이 멈추지 않는다")
    assert_no_match(/display: none|opacity: 0|visibility: hidden/, rule, "구름이 사라진다 — 멈추는 것이지 사라지는 것이 아니다")
  end

  test "구름을 움직이는 스크립트가 없다" do
    scripts = Rails.root.glob("app/javascript/**/*.js").select { |file| file.read.match?(/cloud/i) }

    assert_empty scripts.map { |file| file.relative_path_from(Rails.root).to_s },
      "구름을 스크립트가 움직인다 — 떠가는 것은 CSS 뿐이다"
  end

  private
    def css = @css ||= CSS.read
end
