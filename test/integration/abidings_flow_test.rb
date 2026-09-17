# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리 — 읽고 고르는 안내. 앱이 자리를 정해 주지 않는다.
require "test_helper"

class AbidingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @abidings = nine_abidings
    @user = users(:one)
  end

  test "여섯째 장 — 코끼리 발자국 하나 안에 돌 아홉, 번호는 없다" do
    I18n.available_locales.each do |locale|
      get guide_chapter_path("abidings", locale: locale)

      assert_response :success
      assert_select ".footprint svg.footprint__art path.footprint__stone", count: 9
      assert_select ".footprint svg.footprint__art path.footprint__toe", count: 4
      assert_select ".footprint a.stone", count: 9
      @abidings.each do |abiding|
        assert_select ".footprint a.stone[href=?] .stone__name", abiding_path(abiding, locale: locale),
          text: (locale == :en ? abiding.gloss_en : abiding.ko)
      end
      assert_no_match(/\d/, visible_text, "#{locale} 여섯째 장에 숫자가 있다")
      assert_match Abiding.epigraph(locale)[0, 20], visible_text
      assert_match I18n.t("abidings.footprint.line", locale: locale), visible_text
      assert_match I18n.t("abidings.footprint.source", locale: locale), visible_text
      assert_match I18n.t("abidings.thangka", locale: locale), visible_text
    end
  end

  test "돌은 자리마다 발자국 안의 다른 곳에 놓인다 — 자리는 상수에서" do
    get guide_chapter_path("abidings")

    styles = css_select(".footprint a.stone").map { |stone| stone["style"] }
    assert_equal 9, styles.uniq.size
    @abidings.each do |abiding|
      x, y = abiding.footprint
      assert_select ".footprint a.stone[href=?][style=?]", abiding_path(abiding),
        "left:#{((x - 30) / 3.3).round(2)}%; top:#{((y - 110) / 3.8).round(2)}%"
    end
  end

  # 탕카의 코끼리 아홉 — 안내이지 읽는 이의 자리가 아니다. 앉기의 코끼리와
  # 잇지 않고, 「지금 여기」를 표시하지 않는다.
  test "코끼리 아홉은 검정에서 흼으로 — 앉기의 코끼리와 잇지 않고, 「지금 여기」가 없다" do
    sign_in_as @user
    get guide_chapter_path("abidings")

    ones = css_select(".elephants img.elephants__one[src*=elephant]")
    assert_equal 9, ones.size
    assert_equal (0..8).map { |step| "--whiteness: #{(step / 8.0).round(3)};" }, ones.map { |one| one["style"] }
    assert_select ".elephants .here, .elephants [aria-current], .elephants .current", false
    assert_no_match(/지금 여기|현재 위치|너는 여기|you are here|current(ly)? (place|stage)/i, visible_text)

    view = Rails.root.join("app/views/guide/abidings.html.erb").read
    assert_no_match(/Elephant|whiteness_for|Current\.user|@elephant|sittings/, view, "코끼리 아홉이 앉은 기록과 이어졌다")

    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.elephants__one \{[^}]*brightness\(calc\(var\(--elephant-dark\) \+ var\(--whiteness, 0\)/m, css)
    root = css[/:root \{.*?\n\}/m]
    assert_match(/--elephant-dark: 0\.35;/, root)
    assert_match(/--elephant-light: 2\.4;/, root)
  end

  test "발자국의 색은 :root 에서 온다 — 그림 파일의 색을 쓰지 않는다" do
    partial = Rails.root.join("app/views/abidings/_footprint.html.erb").read
    assert_no_match(/#\h{3,8}\b|fill="|stroke="/, partial, "발자국 그림에 색이 박혀 있다")

    css = Rails.root.join("app/assets/tailwind/application.css").read
    %w[footprint__sole footprint__toe footprint__stone footprint__shadow].each do |part|
      assert_match(/\.#{part} \{[^}]*var\(--(?:paper|paper-deep|ink)\)/, css)
    end
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
