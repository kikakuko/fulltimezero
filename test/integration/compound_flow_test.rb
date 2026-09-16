# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내 — 삼문을 지났으면 경내에 선다. 마당에서 전각으로 가는 길은 이름뿐이다.
require "test_helper"

class CompoundFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "자리 넷은 전각이다 — 마당 · 미륵당 · 선방 · 사경실" do
    get today_path

    assert_select "nav.doors a.door", text: "마당"
    assert_select "nav.doors a.door", text: "미륵당"
    assert_select "nav.doors a.door", text: "선방"
    assert_select "nav.doors a.door", text: "사경실"
    assert_select "nav.doors a.door", count: 4
  end

  test "마당 맨 위에 경내 조감도가 있고, 전각 여섯이 제 자리로 이어진다" do
    get today_path

    assert_select ".compound img.compound__map[src*=compound]", count: 1
    main = Nokogiri::HTML(response.body).css("main").to_html
    assert_operator main.index("compound"), :<, main.index("moon"), "조감도가 맨 위가 아니다"

    { sitting: new_sitting_path, maitreya: days_path, copying: new_copying_path,
      lecture: guide_path, courtyard: "#clearing", gate: threshold_path }.each do |key, href|
      assert_select "a.compound__hall--#{key}[href=?]", href, count: 1, text: I18n.t("compound.halls.#{key}")
    end
    assert_select "#clearing", count: 1, message: "마당을 누르면 내려갈 자리가 없다"
  end

  # 방은 장소이지 할 일이 아니다. 이름 말고는 아무것도 붙지 않는다.
  test "전각에는 이름만 있다 — 시간도 설명도 없다" do
    I18n.available_locales.each do |locale|
      get today_path(locale: locale)

      css_select("a.compound__hall").each do |hall|
        assert_no_match(/\d|·|—|분|min|\(/, hall.text, "#{locale} 전각에 이름 말고 것이 붙었다: #{hall.text}")
        assert_operator hall.text.strip.split.size, :<=, 2, "#{locale} 전각 이름이 설명이 되었다: #{hall.text}"
      end
    end
  end

  test "누르는 자리는 그림 위의 이름뿐이다 — 테두리도 버튼 모양도 없다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    rule = css[/\.compound__hall \{[^}]*\}/]

    assert rule
    assert_no_match(/border(?!-)|background|box-shadow|border-radius/, rule, "전각에 상자를 그렸다")
    assert_match(/font-family: var\(--serif\); font-size: 13px; color: var\(--ink\)/, rule)
    assert_match(/\.compound__name \{[^}]*top: 100%/, css, "이름이 전각 바로 아래가 아니다")
    assert_match(/\.compound \{[^}]*calc\(100% \+ 3rem\)/, css, "조감도가 화면 폭 전체가 아니다")
  end

  test "자리와 크기는 한 곳에서 온다" do
    get today_path

    Compound::HALLS.each do |hall|
      assert_select "a.compound__hall--#{hall.key}[style=?]",
        "left:#{hall.left}%; top:#{hall.top}%; width:#{hall.w}%; height:#{hall.h}%"
    end
    assert_equal 6, Compound::HALLS.size
    Compound::HALLS.each { |hall| assert hall.left >= 0 && hall.top >= 0 && hall.left + hall.w <= 100 && hall.top + hall.h <= 100 }
  end

  test "강원은 마당에서 들어가는 길이고, 아래 자리에는 없다" do
    get today_path

    assert_select "main a[href=?]", guide_path, count: 1
    assert_select "nav.doors a[href=?]", guide_path, false
  end

  test "조감도는 배경이 투명하다 — 어떤 바탕에도 얹힌다" do
    png = Rails.root.join("app/assets/images/compound.png").binread
    assert_equal 6, png.byteslice(25, 1).unpack1("C"), "RGBA 가 아니다"

    # 처리본은 원본과 다르고, 처리하는 손이 저장소에 있다.
    assert Rails.root.join("app/assets/images/compound_src.png").exist?
    assert Rails.root.join("bin/knockout").executable?
    assert_not_equal png, Rails.root.join("app/assets/images/compound_src.png").binread
  end
end
