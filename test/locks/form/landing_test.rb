# This app is a raft. — 이 앱도 뗏목이다.
#
# 첫 화면 — 걸음마다 그림 한 장(docs/M-landing-design.md, 2026-11-06). 원경 → 일주문 B → D3c → 천왕문 왼쪽 벽 → 오른쪽 벽 →
# 불이문 → 마당. 결 자물쇠다: 걸음의 차례와 값은 방향을 틀면 풀 수 있다. 다만 「걸음을 옮겨도 서버에 묻지 않는다」 ·
# 「걸음을 적어 두지 않는다」는 선방 세 걸음(seonbang_steps_test)과 같은 뜻이다.
require "test_helper"

class LandingTest < ActionDispatch::IntegrationTest
  JS = %w[gates_controller gates_steps passage_controller].to_h do |name|
    [ name, Rails.root.join("app/javascript/controllers/#{name}.js").read ]
  end
  FIRST = { "threshold_path" => [ "far", "far" ], "threshold_naming_path" => [ "wall-left", "wall-left" ],
            "threshold_breath_path" => [ "burimun", "burimun" ] }.freeze
  # 화면마다 처음 받는 무게의 상한(2026-11-06 에 정했다). 그림 합계가 늘어도 한 화면이 무거워지지 않게.
  FIRST_LOAD_MOST = 700_000

  setup do
    @user = users(:one)
    @user.update!(onboarded_at: nil)
    sign_in_as @user
  end

  # 새로 고침은 그 화면의 첫 걸음에서 — 걸음을 기억해 되살리지 않는다.
  test "새로 고침하면 그 화면의 첫 걸음에서 시작한다" do
    FIRST.each do |path, (step, shot)|
      get send(path)
      assert_select "#gates[data-step=?]", step
      assert_select ".threshold[data-step=?]", step
      assert_select "#gates img.gates__shot.is-here", count: 1
      assert_select "#gates img.gates__shot--#{shot}.is-here", count: 1
    end
    assert_match(/history\.replaceState\(\{ \.\.\.history\.state, gatesStep: FIRST\[this\.stateValue\] \}, ""\)/, JS["gates_controller"],
                 "처음 그릴 때 지금 칸의 걸음을 첫 걸음으로 바꿔 두지 않는다")
    assert_no_match(/history\.state\??\.gatesStep/, JS["gates_controller"], "기록에 남은 걸음을 읽어 되살린다")
  end

  # 지금 걸음의 그림만 먼저 받는다. 다음 걸음의 그림은 걸음이 멎은 뒤 한 장만 — 데이터를 아끼는 기기면 받지 않는다.
  test "지금 걸음의 그림만 먼저 받고, 다음 한 장은 걸음이 멎은 뒤에 — saveData 면 받지 않는다" do
    FIRST.each_key do |path|
      get send(path)
      assert_select "#gates img.gates__shot[loading=eager]", count: 1
      assert_select "#gates img.gates__shot[loading=lazy]", count: 5
      assert_select "#gates img.gates__shot.is-here[loading=eager]", count: 1
    end
    steps = JS["gates_steps"]
    assert_match(/frame\.nearTimer = setTimeout\(\(\) => prefetchAfter\(step\), entryTime\(\)\)/, steps, "다음 그림을 걸음이 멎기 전에 받는다")
    assert_match(/function prefetchAfter\(step\) \{\s*if \(saveData\(\)\) return/, steps, "데이터를 아끼는 기기에서도 미리 받는다")
    assert_match(/navigator\.connection\?\.saveData === true/, steps)
    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.gates__shot \{[^}]*display: none;/, css, "보이지 않는 그림이 그려져 받힌다")
  end

  # 걸음을 옮겨도 서버에 묻지 않는다. 서버에 가는 것은 지금처럼 문을 지날 때(둘째 문의 주소 · PATCH · pass)뿐이다.
  test "걸음을 옮겨도 서버에 묻지 않고, 걸음을 어디에도 적지 않는다" do
    JS.each do |name, js|
      # 손님이 마당으로 가는 GET 하나(passage 의 gateTarget)는 문을 지나는 것이라 뺀다.
      assert_no_match(/\bfetch\(|XMLHttpRequest|sendBeacon|requestSubmit/, js.gsub("this.gateTarget.requestSubmit()", ""),
                      "#{name} 이 걸음을 옮기며 서버에 묻는다")
      assert_no_match(/localStorage|sessionStorage|document\.cookie|indexedDB/, js, "#{name} 이 걸음을 적어 둔다")
    end
    # 둘째 문으로 가는 것은 「들어간다」 링크의 주소 그대로다.
    assert_match(/window\.Turbo\.visit\(link\.href\)/, JS["gates_controller"])
    assert_match(/history\.pushState\(\{ \.\.\.history\.state, gatesStep: "gate" \}, ""\)/, JS["gates_controller"], "뒤로 가기가 한 걸음 나옴이 아니다")
    assert_match(/history\.pushState\(\{ \.\.\.history\.state, gatesStep: "wall-right" \}, ""\)/, JS["gates_controller"])
  end

  test "움직임을 줄이면 걸음마다 한 장씩 바로 선다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.gates__shot, \.gates__shot--far \{ transition: none; \}\s*\.gates\[data-step="approach"\] \.gates__shot--far, \.gates\[data-step="gate"\] \.gates__shot--far \{ transform: none; \}/, css)
    assert_match(/return reduced\(\) \? 0 :/, JS["gates_steps"], "움직임을 줄인 화면에서 걸음의 시간을 기다린다")
  end

  # 화면마다 처음 받는 무게 — 그 화면을 처음 열 때 받는 것의 합(글 · 스타일 · 스크립트 · 글꼴 · 지금 걸음의 그림 한 장).
  # 받는 쪽은 AVIF. 글꼴은 이 화면에 쓰이는 것(동해독도 · 현판 글꼴)만. 개발 서버에서 잰 실측(첫째 문 574,525,
  # 2026-11-10)과 같은 셈이다 — 압축 전의 파일 크기.
  test "첫 화면은 화면마다 처음 받는 무게가 칠십만 바이트를 넘지 않는다" do
    common = common_bytes
    FIRST.each do |path, (_, shot)|
      get send(path)
      image = Rails.root.join("app/assets/images/landing_#{shot.tr("-", "_")}.avif").size
      total = response.body.bytesize + common + image
      puts "#{path}: #{total}" if ENV["SHOW_WEIGHT"]
      assert_operator total, :<=, FIRST_LOAD_MOST, "#{path} 가 처음에 #{total} 바이트를 받는다(상한 #{FIRST_LOAD_MOST})"
    end
  end

  private
    def common_bytes
      css = Rails.root.join("app/assets/builds/tailwind.css")
      css = css.exist? ? css.size : Rails.root.join("app/assets/tailwind/application.css").size
      js = Rails.root.glob("app/javascript/**/*.js").sum(&:size) +
           Rails.root.glob("vendor/javascript/*.js").sum(&:size) +
           %w[turbo-rails stimulus-rails].sum do |gem|
             Gem.loaded_specs[gem] ? Pathname(Gem.loaded_specs[gem].full_gem_path).glob("app/assets/javascripts/*.min.js").sum(&:size) : 0
           end
      fonts = %w[EastSeaDokdo.woff2 NotoSerifKRPlaque.woff2].sum { |name| Rails.root.join("app/assets/fonts", name).size }
      css + js + fonts
    end
end
