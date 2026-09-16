# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵 — 날들의 달력 위. 비운 날에 올라온다. 숫자는 없다.
require "test_helper"

class MaitreyaFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    sign_in_as @user
  end

  test "달력 위에 미륵이 있고, 얼마나 드러났는지는 그림이 말한다" do
    3.times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }

    get days_path

    assert_select ".maitreya[data-controller=maitreya] img.maitreya__figure[src*=maitreya]", count: 1
    assert_select ".maitreya[data-maitreya-rise-value=?]", (3 / 12.0).to_s
    main = Nokogiri::HTML(response.body).css("main").to_html
    assert_operator main.index("maitreya"), :<, main.index("calendar"), "미륵이 달력 위에 있지 않다"

    text = Nokogiri::HTML(response.body).tap { |page| page.css(".date").each(&:remove) }.css("body").text
    assert_no_match(/\d/, text, "날들 화면에 날짜 말고 숫자가 있다")
    assert_no_match(/열둘|중 |of twelve|out of/i, text, "몇 번인지 말한다")
  end

  test "땅 · 흙먼지 · 물결은 앱이 그리고, 미륵은 그림 한 장이다" do
    get days_path

    assert_select ".maitreya__ground .maitreya__figure", count: 1
    assert_select ".maitreya__dust", count: 1
    assert_select ".maitreya__ripple", count: 1
    assert_select ".maitreya img", count: 1

    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.maitreya__ground \{[^}]*overflow: hidden/, css)
    assert_match(/\.maitreya--moving \.maitreya__figure \{ transition: transform 1\.2s ease-out; \}/, css)
    assert_match(/\.maitreya--rising \.maitreya__dust \{ animation: maitreya-dust 1\.2s ease-out both; \}/, css)
  end

  test "비운 날 아침 첫 화면에서만 한 뼘 올라온다" do
    travel_to Time.utc(2026, 8, 26, 22, 0) do # 서울 아침 일곱시
      @user.clearings.create!(cleared_on: @user.today)

      get days_path
      assert_select ".maitreya--rising[data-maitreya-rising-value=true]", count: 1
      assert_select ".maitreya[data-maitreya-before-value=?]", 0.0.to_s

      get days_path
      assert_select ".maitreya--rising", false, "같은 아침에 두 번 올라온다"
    end
  end

  test "비우지 않은 날 아침에는 올라오지 않는다" do
    travel_to Time.utc(2026, 8, 26, 22, 0) do
      get days_path
      assert_select ".maitreya--rising", false
    end
  end

  test "비운 날 저녁에는 올라오지 않는다 — 아침의 것이다" do
    travel_to Time.utc(2026, 8, 27, 11, 0) do # 서울 저녁 여덟시
      @user.clearings.create!(cleared_on: @user.today)

      get days_path
      assert_select ".maitreya--rising", false
    end
  end

  test "열두 번이면 다 올라오고 다시 묻히지 않는다" do
    14.times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }

    get days_path
    assert_select ".maitreya[data-maitreya-rise-value='1.0']", count: 1
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
