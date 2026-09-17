# This app is a raft. — 이 앱도 뗏목이다.
#
# 첫째 문의 빛 — 둥근 빛이 다가오고, 흰빛이 한 번 넘쳤다가 가라앉는다.
# 매일의 문은 같은 장면을 짧게. 빛의 색은 때를 따르되, 세지도 적지도 않는다.
require "test_helper"

class GateLightTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  # 피그마 gate1-light-v2 의 여섯 때 — (초, cy, r, dark, 넘침)
  MOMENTS = [
    [ 0.0, 0.13, 0.16, 0.95, 0 ],
    [ 0.9, 0.28, 0.30, 0.90, 0 ],
    [ 1.8, 0.45, 0.48, 0.82, 0 ],
    [ 2.6, 0.66, 0.72, 0.66, 0 ],
    [ 3.0, 0.72, 1.30, 0.30, 0.55 ],
    [ 3.8, 0.72, 1.60, 0.16, 0 ]
  ].freeze

  test "여섯 때의 값은 :root 상수이고, 때의 비율이 3.8초에 맞다" do
    css = CSS.read
    root = css[/:root \{.*?\n\}/m]

    assert_match(/--light-arrive: 3\.8s;/, root)
    assert_match(/--light-daily: 1\.6s;/, root)
    assert_match(/--light-flood-peak: 0\.55;/, root)

    keyframes = css[/@keyframes gate-light \{.*?\n\}/m]
    MOMENTS.each_with_index do |(second, cy, r, dark, _), i|
      assert_match(/--light-cy-#{i}: #{format('%.2f', cy)}; --light-r-#{i}: #{format('%.2f', r)}; --light-dark-#{i}: #{format('%.2f', dark)};/, root)
      percent = format("%g", (second / 3.8 * 100).round(2))
      assert_match(/^\s*#{Regexp.escape(percent)}%\s*\{ --light-cy: var\(--light-cy-#{i}\);/, keyframes, "#{second}초의 자리가 어긋났다")
    end

    flood = css[/@keyframes gate-flood \{.*?\n\}/m]
    assert_match(/0%, 68\.42%\s*\{ opacity: 0; \}\s*78\.95%\s*\{ opacity: var\(--light-flood-peak\); \}\s*100%\s*\{ opacity: 0; \}/, flood,
                 "흰빛이 한 번 넘치지 않는다")
  end

  test "빛은 방사형이고 중심은 가로 가운데에 고정된다" do
    light = CSS.read[/\.gates__light \{.*?\n\}/m]

    assert_match(/radial-gradient\(circle calc\(var\(--light-r\) \* 100cqw\) at 50% calc\(var\(--light-cy\) \* 100%\)/, light)
    assert_match(/transparent 0%,\s*.*?calc\(var\(--light-dark\) \* 25%\).*?45%,\s*.*?\* 75%\).*?78%,\s*.*?\* 100%\).*?100%\)/m, light)
    assert_match(/var\(--night-gate\)/, light)
  end

  test "움직임을 줄이면 빛은 처음부터 닿은 자리에 있다" do
    css = CSS.read

    assert_match(/\.gates__light \{[^}]*--light-cy: var\(--light-cy-5\); --light-r: var\(--light-r-5\); --light-dark: var\(--light-dark-5\);/m, css)
    css.scan(/^.*animation: gate-(?:light|flood|word|later).*$/).each do |line|
      block = css[0, css.index(line)].rpartition("@media").last
      assert_match(/\A \(prefers-reduced-motion: no-preference\)/, block, "움직임을 줄여도 움직인다: #{line.strip}")
    end
  end

  test "빛의 때 — 새벽 · 낮 · 저녁 · 밤" do
    { 4 => :night, 5 => :dawn, 7 => :dawn, 8 => :day, 16 => :day, 17 => :evening, 19 => :evening, 20 => :night, 0 => :night }.each do |hour, light|
      assert_equal light, GateLight.at(hour), "#{hour}시"
    end

    js = Rails.root.join("app/javascript/controllers/gates_controller.js").read
    GateLight::HOURS.each do |name, range|
      assert_match(/#{name}: \[#{range.begin}, #{range.end}\]/, js, "브라우저의 #{name} 경계가 서버와 다르다")
    end

    root = CSS.read[/:root \{.*?\n\}/m]
    { dawn: "#eef2f5", day: "#fbf7ec", evening: "#f7e6d6", night: "#e8ecf2" }.each do |name, color|
      assert_match(/--light-#{name}: #{color};/, root)
    end
    assert_match(/--light-night-dim: 0\.15;/, root, "밤의 밝기가 0.85배가 아니다")
  end

  test "빛의 색은 사용자의 시간대를 따른다" do
    user = users(:one)
    user.update!(time_zone: "Asia/Seoul", onboarded_at: nil)
    sign_in_as user

    travel_to Time.utc(2026, 9, 17, 11, 0) do # 서울 저녁 여덟 시
      get threshold_path
      assert_select "#gates[data-light=night]"
    end
    travel_to Time.utc(2026, 9, 16, 21, 30) do # 서울 새벽 여섯 시 반
      get threshold_path
      assert_select "#gates[data-light=dawn]"
    end
  end

  # 지금이 몇 시인지를 빛이 알 뿐이다. 어떤 빛을 보았는지 남기지 않는다.
  test "빛은 세지도 적지도 않는다" do
    schema = Rails.root.join("db/schema.rb").read
    assert_no_match(/light/, schema, "빛을 적는 칸이 생겼다")

    scripts = %w[gates_controller daily_door_controller].map { |name| Rails.root.join("app/javascript/controllers/#{name}.js").read }.join
    assert_no_match(/localStorage|sessionStorage|document\.cookie|fetch\(/, scripts)

    I18n.available_locales.each do |locale|
      copy = Rails.root.join("config/locales/#{locale}.yml").read
      assert_no_match(/빛을 보았|새벽빛을|밤의 빛|saw the (?:night|dawn)/i, copy)
    end
  end

  test "매일의 문은 같은 그림과 같은 빛이고, 글이 없다" do
    user = users(:one)
    sign_in_as user
    get today_path

    assert_select ".daily-door[data-light] .gates__frame img.gates__image[alt='']", count: 1
    assert_select ".daily-door .gates__light", count: 1
    assert_select ".daily-door .gates__flood", count: 1
    assert_select ".daily-door", text: ""
    assert_select ".daily-door[data-action*='animationend->daily-door#settled']"

    js = Rails.root.join("app/javascript/controllers/daily_door_controller.js").read
    assert_match(/settled\(event\) \{\s*if \(event\.target === this\.element\) this\.pass\(\)/, js, "안쪽 빛이 끝나자마자 걷힌다")
  end
end
