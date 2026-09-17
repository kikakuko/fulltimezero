# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 미륵당 마당에 묻혀 있다가, 오늘을 비워 두는 순간 땅이 울리며 드러난다.
require "test_helper"

class MaitreyaFlowTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    sign_in_as @user
  end

  test "미륵당 — 마당 그림 위에 묻힌 미륵이 있고, 얼마나 드러났는지는 그림이 말한다" do
    3.times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }

    get days_path

    assert_select ".maitreya img.maitreya__yard[src*=mireukdang]", count: 1
    assert_select ".maitreya .maitreya__earth img.maitreya__figure[src*=maitreya]", count: 1
    assert_select ".maitreya[style*=?]", "--shown-to: #{Maitreya.at(3).shown};"
    assert_select ".maitreya__heap", count: 1
    assert_select ".maitreya__cracks path", count: 5
    main = Nokogiri::HTML(response.body).css("main").to_html
    assert_operator main.index("maitreya"), :<, main.index("calendar"), "미륵이 달력 위에 있지 않다"

    text = Nokogiri::HTML(response.body).tap { |page| page.css(".date").each(&:remove) }.css("body").text
    assert_no_match(/\d/, text, "날들 화면에 날짜 말고 숫자가 있다")
    assert_no_match(/열둘|스물넷|중 |of twenty|out of/i, text, "몇 번인지 말한다")
  end

  test "땅선 아래는 잘린다 — 미륵을 반쯤 띄워 두지 않는다" do
    css = CSS.read

    assert_match(/\.maitreya__earth \{[^}]*height: calc\(470 \* var\(--m-u\)\); overflow: hidden;/, css)
    assert_match(/\.maitreya__figure \{[^}]*top: calc\(\(470 - var\(--shown\) \* 340\) \* var\(--m-u\)\);/m, css)
    assert_match(/\.maitreya__figure \{[^}]*width: calc\(340 \* 534 \/ 768 \* var\(--m-u\)\);/m, css, "미륵의 틀이 폭 340 이 아니다")
    assert_match(/\.maitreya \{[^}]*aspect-ratio: 390 \/ 560;/m, css)
  end

  test "날들에서는 솟지 않는다 — 아침의 장면은 없다" do
    travel_to Time.utc(2026, 8, 26, 22, 0) do # 서울 아침 일곱시
      @user.clearings.create!(cleared_on: @user.today)
      get days_path
    end

    assert_select ".maitreya-scene", false
    assert_select ".maitreya[style*=?]", "--shown-from: #{Maitreya.at(1).shown};"
    assert_select "[data-maitreya-rising-value]", false
  end

  test "오늘을 비워 두는 손짓에 솟는 장면이 실려 있다 — 전과 뒤를 함께" do
    2.times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }
    get today_path

    assert_select "#clearing[data-controller=maitreya] button[data-action*='click->maitreya#rise']", count: 1
    assert_select "#clearing template[data-maitreya-target=scene]", count: 1
    scene = Nokogiri::HTML(css_select("template").first.inner_html)
    maitreya = scene.at_css(".maitreya-scene .maitreya")
    assert_includes maitreya["style"], "--shown-from: #{Maitreya.at(2).shown};"
    assert_includes maitreya["style"], "--shown-to: #{Maitreya.at(3).shown};"
    assert_empty scene.css(".maitreya-scene__line"), "사이의 날에 한 줄이 뜬다"
    assert_empty scene.css(".maitreya__many"), "사이의 날에 지용이 온다"
    assert_equal 1, scene.css(".maitreya-scene__back a").size
  end

  test "한 줄 「멈추면 이미 미륵」은 처음 비운 날에 뜬다" do
    get today_path
    scene = Nokogiri::HTML(css_select("template").first.inner_html)

    assert_equal I18n.t("maitreya.line"), scene.at_css(".maitreya-scene__line").text
    assert_empty scene.css(".maitreya__many")
  end

  test "다 올라오는 날 — 한 줄과 함께 지평선 곳곳에서 작은 미륵들이 솟는다" do
    (Maitreya::FULL - 1).times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }
    get today_path
    scene = Nokogiri::HTML(css_select("template").first.inner_html)

    assert_equal I18n.t("maitreya.line"), scene.at_css(".maitreya-scene__line").text
    assert_includes 5..7, scene.css(".maitreya__many .maitreya__one img").size
  end

  test "장면은 하루 한 번 — 비웠다가 거두고 다시 비워도 오지 않는다" do
    get today_path
    assert_select "template[data-maitreya-target=scene]", count: 1

    patch day_path(@user.today, from: "today")
    get today_path
    assert_select "template[data-maitreya-target=scene]", false, "비운 날에 장면이 남아 있다"

    patch day_path(@user.today, from: "today") # 거둔다
    get today_path
    assert_select "template[data-maitreya-target=scene]", false, "같은 날 다시 장면이 온다"
  end

  test "앞날을 비워 두는 것은 장면을 쓰지 않는다" do
    patch day_path(@user.today + 2)
    get today_path

    assert_select "template[data-maitreya-target=scene]", count: 1
  end

  test "넉 초에 전부 멎는다 — 흔들림 · 먼지 · 금빛의 결" do
    css = CSS.read

    shake = css[/@keyframes maitreya-shake \{.*?\n\}/m]
    assert_match(/12\.50% \{ transform: translateX\(-?3\.0px\); \}/, shake, "0.5초에 ±3px 가 아니다")
    assert_match(/30\.00% \{ transform: translateX\(-?5\.0px\); \}/, shake, "1.2초에 ±5px 가 아니다")
    assert_match(/50\.00% \{ transform: translateX\(-?2\.0px\); \}/, shake, "2.0초에 ±2px 가 아니다")
    assert_match(/75%, 100% \{ transform: translateX\(0\); \}/, shake, "3.0초에 멎지 않는다")

    assert_match(/@keyframes maitreya-dust \{\s*0% \{ opacity: 0; \} 12\.5% \{ opacity: 0\.35; \} 50% \{ opacity: 1;.*75% \{ opacity: 0\.35; \} 100% \{ opacity: 0;/m, css)
    assert_match(/@keyframes maitreya-sky \{ 0% \{ opacity: 0; \} 30% \{ opacity: 0\.5; \} 75% \{ opacity: 0\.1; \} 100% \{ opacity: 0; \} \}/, css)
    assert_match(/100% \{ stroke-dashoffset: 0; opacity: 0\.35; \}/, css, "금이 옅게 남지 않는다")
    assert_match(/--maitreya-gold: #f3e2b8;/, css)

    js = Rails.root.join("app/javascript/controllers/maitreya_controller.js").read
    assert_equal 4000, js[/const SCENE = (\d+)/, 1].to_i
    assert_equal 300, js[/const FADE = (\d+)/, 1].to_i
  end

  test "입자도 색종이도 반짝임도 없다 — 먼지는 흙이다" do
    css = CSS.read[/\/\* ── 미륵 — 묻혀 있다가.*?\/\* ── 코끼리의 길/m]

    assert_no_match(/confetti|sparkle|particle|star|twinkle|--cinnabar/i, css)
    assert_no_match(/confetti|sparkle|particle|Math\.random/, Rails.root.join("app/javascript/controllers/maitreya_controller.js").read)
  end

  test "움직임을 줄이면 흔들림과 먼지 없이 미륵만 조용히 올라온다" do
    css = CSS.read

    %w[maitreya-shake maitreya-dust maitreya-sky maitreya-crack maitreya-ripple].each do |name|
      css.scan(/^.*animation: #{name}\b.*$/).each do |line|
        block = css[0, css.index(line)].rpartition("@media").last
        assert_match(/\A \(prefers-reduced-motion: no-preference\)/, block, "움직임을 줄여도 #{name} 가 돈다")
      end
    end
    rise = css[/\.maitreya-scene--playing \.maitreya \{[^}]*\}/]
    assert_match(/transition: --shown/, rise, "미륵이 올라오지 않는다")
    assert_equal "", css[0, css.index(rise)].rpartition("@media").last[/\A \(prefers-reduced-motion: no-preference\) \{[^}]*\z/].to_s,
                 "움직임을 줄이면 미륵도 올라오지 않는다"
  end

  test "선언은 누르는 순간 보내고, 아무 곳이나 누르면 곧장 끝난다" do
    js = Rails.root.join("app/javascript/controllers/maitreya_controller.js").read

    assert_match(/event\.preventDefault\(\)\s*const form = event\.target\.closest\("form"\)\s*this\.saved = fetch\(form\.action/, js)
    assert_match(/scene\.addEventListener\("click",[^}]*this\.finish\(\)/m, js)
    assert_no_match(/navigator\.vibrate/, js, "게이트를 거치지 않고 떤다")
  end

  # 「오늘을 비워 둔다」를 누르는 그 손짓 안에서만 떤다. 거두는 손짓에는 떨지 않는다.
  test "비우는 손짓 안에서 떨고, 거두는 손짓에는 떨지 않는다" do
    get today_path
    assert_select "form[data-controller~=clearing][data-clearing-declaring-value=true][data-clearing-vibrate-value=true]"
    assert_select "form[data-controller~=bell][data-bell-enabled-value=false]", count: 1, message: "종성이 기본으로 켜져 있다"

    @user.clearings.create!(cleared_on: @user.today)
    get today_path
    assert_select "form[data-controller~=clearing][data-clearing-declaring-value=false]"
  end

  test "떨림의 결은 게이트가 정한다" do
    js = Rails.root.join("app/javascript/controllers/clearing_controller.js").read

    assert_match(/const RUMBLE = \[ 180, 80, 60, 80, 60 \]/, js)
    assert_match(/touch\(RUMBLE, this\.vibrateValue\)/, js)
    assert_no_match(/navigator\.vibrate/, js, "게이트를 거치지 않고 떤다")
  end

  test "종성은 기본으로 꺼져 있고, 설정에서 켠다" do
    refute @user.clearing_sound
    refute User.columns_hash["clearing_sound"].default.in?([ true, "1", "t" ])

    patch settings_path, params: { user: { clearing_sound: "1" } }
    assert @user.reload.clearing_sound

    get today_path
    assert_select "form[data-controller~=bell][data-bell-enabled-value=true]", count: 1
  end

  # 종성은 침묵의 시각에도 울릴 수 있는 유일한 소리다 — 사용자가 그 자리에서
  # 켜고 누르는 소리이므로. 비우는 손짓의 종성도 같은 종이다.
  test "비우는 손짓의 종성도 게이트를 지난다" do
    @user.update!(clearing_sound: true)
    get today_path

    assert_select "form[data-controller~=bell][data-bell-enabled-value=?]",
      SilenceGate.allow?(:bell, user: @user).to_s, count: 1
  end
end
