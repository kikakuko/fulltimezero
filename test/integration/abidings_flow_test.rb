# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리 — 읽고 고르는 안내. 앱이 자리를 정해 주지 않는다.
require "test_helper"

class AbidingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @abidings = nine_abidings
    @user = users(:one)
  end

  test "여섯째 장에 돌 아홉이 흩어져 있고, 번호는 없다" do
    %i[ko en].each do |locale|
      get guide_chapter_path("abidings", locale: locale)

      assert_response :success
      assert_select ".stones .stone", count: 9
      @abidings.each do |abiding|
        assert_select ".stone[href=?] .stone__name", abiding_path(abiding, locale: locale),
          text: (locale == :en ? abiding.gloss_en : abiding.ko)
      end
      assert_no_match(/\d/, visible_text, "#{locale} 여섯째 장에 숫자가 있다")
      assert_match Abiding.epigraph(locale)[0, 20], visible_text
    end
  end

  test "돌은 자리마다 다른 곳에 놓인다 — 화면의 자리는 파일이 아니라 상수에서" do
    get guide_chapter_path("abidings")

    styles = css_select(".stones .stone").map { |stone| stone["style"] }
    assert_equal 9, styles.uniq.size
  end

  test "자리 하나를 읽는다 — 이름 · 한 줄 · 일어나는 일 · 앉을 때" do
    abiding = @abidings.fetch(3)

    %i[ko en].each do |locale|
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

  test "자리를 두지 않고도 앉는다" do
    sign_in_as @user

    post sittings_path, params: { sitting: { length: "tea", abiding: "" } }
    assert_nil @user.sittings.last.abiding

    follow_redirect!
    assert_match I18n.t("sittings.hint"), visible_text
  end

  test "지난번 고른 자리가 다음 앉기에 그대로 있고, 안내에서 오면 그 자리다" do
    sign_in_as @user
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(6))

    get new_sitting_path
    assert_select "#abiding_7[checked]", count: 1

    get new_sitting_path(abiding: 2)
    assert_select "#abiding_2[checked]", count: 1
  end

  # 자리는 사람을 판정하지 않는다. 어느 자리를 몇 번 골랐는지 어디에도 없다.
  test "앉기 화면은 자리를 세지도 권하지도 않는다" do
    sign_in_as @user
    3.times { @user.sittings.create!(mode: "sitting", abiding: @abidings.first, ended_at: Time.current) }

    get new_sitting_path
    assert_no_match(/번|times|회|권한다|recommend|suggest|다음 자리|next/i, visible_text.sub(/한국어.*/, ""))
  end

  test "고른 자리는 사용자의 것이라 내보내기에 담긴다" do
    @user.sittings.create!(mode: "sitting", abiding: @abidings.fetch(2), ended_at: Time.current)

    assert_equal @abidings.fetch(2).ko, JSON.parse(Export.new(@user).json)["sittings"].last["abiding"]
  end

  private
    def visible_text = Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
end
