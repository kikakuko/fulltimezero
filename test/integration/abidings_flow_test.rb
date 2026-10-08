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

  # 자리 고르기는 걷었다(2026-10-08). 안내의 「이 자리로 앉는다」는 선방으로 가는 문일
  # 뿐이고, 선방에는 고르는 돌이 없다 — sitting_form_test 가 지킨다.
end
