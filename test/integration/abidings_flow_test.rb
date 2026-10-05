# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리가 도는가 — 자리를 읽고, 골라 앉고, 고른 자리가 다음에도 있다. 깨지면 버그다.
require "test_helper"

class AbidingsFlowTest < ActionDispatch::IntegrationTest
  include Screens
  setup do
    @abidings = nine_abidings
    @user = users(:one)
  end


  test "자리 하나를 읽는다 — 이름 · 한 줄 · 일어나는 일 · 앉을 때" do
    abiding = @abidings.fetch(3)

    I18n.available_locales.each do |locale|
      get abiding_path(abiding, locale: locale)

      assert_response :success
      text = visible_text
      assert_match abiding.han, text
      assert_match (locale == :en ? abiding.one_line_en : abiding.one_line), text
      assert_match (locale == :en ? abiding.what_to_do_en : abiding.what_to_do), text
      assert_match (locale == :en ? abiding.image_en : abiding.image), text
      assert_no_match(/\d/, text, "#{locale} 자리 화면에 숫자가 있다")
      assert_no_match(/째 자리|다음 자리|next (place|abiding)|\bstep\b/i, text, "자리에 차례가 붙었다")
    end
  end

  test "없는 자리는 아홉 자리 장으로 돌려보낸다" do
    get abiding_path(pos: 12)

    assert_redirected_to guide_chapter_path("abidings")
  end

  test "로그인 없이도 읽을 수 있고, 앉는 길은 들어온 사람에게만 보인다" do
    get abiding_path(@abidings.first)
    assert_response :success
    assert_select "a[href*=?]", new_sitting_path, false

    sign_in_as @user
    get abiding_path(@abidings.first)
    assert_select "a[href=?]", new_sitting_path(abiding: 1)
  end

  test "앉기에서 자리를 고르면 그 자리로 앉고, 앉는 중에 그 자리의 한 줄이 뜬다" do
    sign_in_as @user
    abiding = @abidings.fetch(4)

    get new_sitting_path
    assert_select ".stones .stone input[type=radio]", count: 9
    assert_select "#abiding_none[checked]", count: 1, message: "처음에는 자리를 두지 않는다"

    post sittings_path, params: { sitting: { length: "tea", abiding: abiding.pos } }
    sitting = @user.sittings.last
    assert_equal abiding, sitting.abiding

    follow_redirect!
    assert_match abiding.sit_hint, visible_text
    assert_no_match I18n.t("sittings.hint"), visible_text
    assert_no_match abiding.ko, visible_text, "앉는 중에 자리의 이름이 붙는다"
  end

  test "지난번 고른 자리가 다음 앉기에 그대로 있고, 안내에서 오면 그 자리다" do
    sign_in_as @user
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(6))

    get new_sitting_path
    assert_select "#abiding_7[checked]", count: 1

    get new_sitting_path(abiding: 2)
    assert_select "#abiding_2[checked]", count: 1
  end
end
