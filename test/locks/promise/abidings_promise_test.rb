# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리의 약속 — 앱이 자리를 정해 주지 않는다. 이것이 아홉 자리가 사다리가 아닌
# 까닭이다. 코끼리(흔적)와 아홉 자리(안내)를 코드로 이으면 앱이 「당신은 다섯째요」라고
# 말하게 된다. 생김새와 배치는 결 쪽이다 — test/locks/form/abidings_form_test.rb.
require "test_helper"

class AbidingsPromiseTest < ActionDispatch::IntegrationTest
  # 화면의 글자를 꺼내는 손은 공용이다(test/test_helpers/screens.rb).
  include Screens

  setup do
    @abidings = nine_abidings
    @user = users(:one)
  end

  # 고르지 않아도 앉는다. 세지도, 권하지도 않는다.
  test "자리를 두지 않고도 앉는다" do
    sign_in_as @user

    post sittings_path, params: { sitting: { length: "tea", abiding: "" } }
    assert_nil @user.sittings.last.abiding

    follow_redirect!
    assert_match I18n.t("sittings.hint"), visible_text
  end

  # 자리는 사람을 판정하지 않는다. 어느 자리를 몇 번 골랐는지 어디에도 없다.
  test "앉기 화면은 자리를 세지도 권하지도 않는다" do
    sign_in_as @user
    3.times { @user.sittings.create!(mode: "sitting", abiding: @abidings.first, ended_at: Time.current) }

    get new_sitting_path
    assert_no_match(/번|times|회|권한다|recommend|suggest|다음 자리|next/i, visible_text.sub(/한국어.*/, ""))
  end

  # 탕카의 코끼리 아홉 — 안내이지 읽는 이의 자리가 아니다. 앉기의 코끼리와
  # 잇지 않고, 「지금 여기」를 표시하지 않는다.
  test "코끼리 아홉은 검정에서 흼으로 — 앉기의 코끼리와 잇지 않고, 「지금 여기」가 없다" do
    sign_in_as @user
    get guide_chapter_path("abidings")

    ones = css_select(".elephants .elephants__one .elephant")
    assert_equal 9, ones.size
    assert_equal (0..8).map { |step| "--ele: #{(step / 8.0).round(3)};" }, ones.map { |one| one["style"] }
    assert_empty ones.select { |one| one["class"].match?(/walking|scatter/) }, "장경각의 코끼리 아홉이 걷거나 흩어진다"
    assert_select ".elephants .here, .elephants [aria-current], .elephants .current", false
    assert_no_match(/지금 여기|현재 위치|너는 여기|you are here|current(ly)? (place|stage)/i, visible_text)

    view = Rails.root.join("app/views/guide/abidings.html.erb").read
    assert_no_match(/Elephant|whiteness_for|Current\.user|@elephant|sittings/, view, "코끼리 아홉이 앉은 기록과 이어졌다")

    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_no_match(/\.elephants__one \{[^}]*(?:brightness|filter)/m, css, "코끼리 아홉이 다른 색 계산을 쓴다")
    root = css[/:root \{.*?\n\}/m]
    assert_match(/--elephant-dark: 0\.35;/, root)
    assert_match(/--elephant-light: 2\.4;/, root)
  end

  test "고른 자리는 사용자의 것이라 내보내기에 담긴다" do
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(2), ended_at: Time.current)

    assert_equal @abidings.fetch(2).ko, JSON.parse(Export.new(@user).json)["sittings"].last["abiding"]
  end

  # 자리는 사람을 판정하지 않는다. 쉰 날의 수로 자리를 부여하는 코드가 없다.
  # 쉰 날의 수로 자리를 부여하지 않는다 — 앱이 자리를 정해 주지 않는다는 약속의 모델 쪽이다.
  test "쉰 날의 수로 자리를 부여하지 않는다" do
    sources = Rails.root.glob("app/**/*.rb").map(&:read).join

    assert_no_match(/Abiding\.(?:for|of|reached|current|assign|by_count|from_days)/, sources,
      "코드가 사용자에게 자리를 부여한다")
    assert_no_match(/sittings\.(?:group|count)\([^)]*abiding/, sources, "자리별로 앉음을 센다")
  end
end
