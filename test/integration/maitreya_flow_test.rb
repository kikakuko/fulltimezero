# This app is a raft. — 이 앱도 뗏목이다.
#
# 미륵이 도는가 — 오늘을 비우면 솟는 장면이 실리고, 하루 한 번은 계정에 붙는다. 깨지면 버그다.
require "test_helper"

class MaitreyaFlowTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")
  setup do
    @user = users(:one)
    @user.clearings.destroy_all
    sign_in_as @user
  end


  test "오늘을 비워 두는 손짓에 솟는 장면이 실려 있다 — 전과 뒤를 함께" do
    2.times { |i| @user.clearings.create!(cleared_on: @user.today - i - 1) }
    get day_path(@user.today)

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

  test "장면은 하루 한 번 — 비웠다가 거두고 다시 비워도 오지 않는다" do
    get day_path(@user.today)
    assert_select "template[data-maitreya-target=scene]", count: 1

    patch day_path(@user.today, from: "today")
    get day_path(@user.today)
    assert_select "template[data-maitreya-target=scene]", false, "비운 날에 장면이 남아 있다"

    patch day_path(@user.today, from: "today") # 거둔다
    get day_path(@user.today)
    assert_select "template[data-maitreya-target=scene]", false, "같은 날 다시 장면이 온다"
  end

  # 하루 한 번은 브라우저가 아니라 계정에 붙는다 — 한 기기를 둘이 써도 둘 다 제 장면을 본다.
  test "하루 한 번은 계정에 붙는다 — 한 브라우저에서 두 계정이 각자 제 장면을 본다" do
    two = users(:two)
    two.clearings.destroy_all

    get day_path(@user.today)
    assert_select "template[data-maitreya-target=scene]", count: 1
    patch day_path(@user.today, from: "today")
    assert_equal @user.today, @user.reload.maitreya_seen_on

    sign_in_as two # 같은 브라우저 세션에서 다른 계정으로
    get day_path(@user.today)
    assert_select "template[data-maitreya-target=scene]", count: 1, message: "앞사람이 본 장면 때문에 뒷사람이 못 본다"

    source = Rails.root.glob("app/**/*.rb").map(&:read).join
    assert_no_match(/session\[:maitreya/, source, "장면을 본 날이 아직 세션에 남는다")
  end

  test "앞날을 비워 두는 것은 장면을 쓰지 않는다" do
    patch day_path(@user.today + 2)
    get day_path(@user.today)

    assert_select "template[data-maitreya-target=scene]", count: 1
  end
end
