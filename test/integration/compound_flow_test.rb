# This app is a raft. — 이 앱도 뗏목이다.
#
# 경내 — 삼문을 지났으면 경내에 선다. 마당에서 전각으로 가는 길은 이름뿐이다.
require "test_helper"

class CompoundFlowTest < ActionDispatch::IntegrationTest
  setup do
    heart_sutra
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
    # 그림 위의 이름은 작다 — 명조는 18px 이상에만 쓰므로 고딕이다.
    assert_match(/font-family: var\(--sans\); font-size: 13px; color: var\(--ink\)/, rule)
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

  # 전각에 드는 흐름 — 마당을 뺀 다섯 전각을 누르면 카드가 뜬다.
  test "다섯 전각에 카드로 드는 손짓이 있고, 마당은 곧장 아래로 간다" do
    get today_path

    Compound::CARD_HALLS.each do |hall|
      assert_select "a.compound__hall--#{hall.key}[data-action*='click->compound#open']", count: 1
      assert_select "a.compound__hall--#{hall.key}[data-compound-key-param=?]", hall.key.to_s
      assert_select "a.compound__hall--#{hall.key}[data-compound-han-param=?]", hall.han
    end
    assert_select "a.compound__hall--courtyard[data-action]", false, "마당이 카드를 연다"
    assert_equal 5, Compound::CARD_HALLS.size
  end

  # 카드의 글 — 이름 · 한자 · 한 줄 · 경구 · 「드는」 말은 데이터 속성으로,
  # 숫자가 없다. 출전(숫자를 담을 수 있는 자리)은 미륵당만 여기 있고,
  # 나머지 넷은 자리 쪽 스크립트의 상수에서 온다.
  test "카드의 글에는 숫자가 없다 — 출전은 미륵당만 예외로 여기 있다" do
    get today_path
    doc = Nokogiri::HTML(response.body)

    Compound::CARD_HALLS.each do |hall|
      anchor = doc.at_css("a.compound__hall--#{hall.key}")
      %w[name han line verse enter].each do |field|
        value = anchor["data-compound-#{field}-param"]
        assert value.present?, "#{hall.key}.#{field} 이 없다"
        assert_no_match(/\d/, value, "#{hall.key}.#{field} 에 숫자가 있다: #{value}")
      end

      source = anchor["data-compound-source-param"]
      if hall.key == :maitreya
        assert source.present?, "미륵당의 출전이 없다"
        assert_no_match(/\d/, source, "미륵당의 출전에 숫자가 있다")
      else
        assert_nil source, "#{hall.key} 의 출전이 화면(서버 응답)에 있다 — 숫자를 담을 수 있는 자리다"
      end
    end
  end

  # 넷의 출전은 스크립트 쪽 상수에 있다. 「미륵」이라는 낱말과 한 파일에
  # 있으면 안 된다 — elephant_test 와 같은 결의 자물쇠다.
  test "출전 넷은 스크립트에 있고, 미륵당이라는 낱말과 섞이지 않는다" do
    js = Rails.root.join("app/javascript/controllers/compound_controller.js").read

    assert_match(/const SOURCES = \{/, js)
    %w[14 12 204 86].each { |digit| assert_match(/#{digit}/, js, "#{digit} 이 출전 상수에 없다") }
    assert_no_match(/maitreya/, js, "미륵당이라는 낱말이 숫자를 담은 파일에 있다")
  end

  test "조감도가 커지는 자리는 눌린 전각의 중심이고, 한지빛으로 옅어진다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/\.compound--zooming \.compound__scene \{[^}]*transform: scale\(2\.6\);/, css)
    assert_match(/transform-origin: var\(--zoom-x, 50%\) var\(--zoom-y, 50%\);/, css)
    assert_match(/\.compound--zooming \.compound__veil \{ opacity: 1; transition: opacity 0\.7s ease-in; \}/, css)

    js = Rails.root.join("app/javascript/controllers/compound_controller.js").read
    assert_match(/this\.sceneTarget\.style\.setProperty\("--zoom-x", `\$\{cx\}%`\)/, js)
  end

  # 카드를 열고 읽는 것은 구조이지 움직임이 아니다 — 그대로 뜨고, 확대만 건너뛴다.
  test "움직임을 줄이면 카드는 그대로 뜨고 확대만 건너뛴다" do
    js = Rails.root.join("app/javascript/controllers/compound_controller.js").read

    assert_match(/prefers-reduced-motion: reduce.*matches.*return this\.go\(href\)/m, js)
    assert_no_match(/prefers-reduced-motion.*open\(/m, js, "카드 자체가 움직임을 줄이면 사라진다")
  end

  # 경구의 강조는 --cinnabar 를 쓰지 않는다 — 하루 한 번의 규칙과 부딪힌다.
  test "카드의 경구는 주사가 아니라 단청 황토를 쓴다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    verse = css[/\.compound__card-verse \{[^}]*\}/]
    halo = css[/\.compound__halo \{[^}]*\}/m]

    assert_match(/color: var\(--dancheong-ocher\)/, verse)
    assert_no_match(/--cinnabar/, verse)
    assert_no_match(/--cinnabar/, halo)
  end

  test "카드의 바탕색은 :root 토큰에서 온다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/--paper-card: #fbf9f4;/, css)
    assert_match(/\.compound__card \{[^}]*background: var\(--paper-card\);/, css)
    assert_no_match(/#fbf9f4/i, css.sub(/--paper-card: #fbf9f4;/, ""), "카드 바탕색이 :root 밖에도 있다")
  end

  # 방 머리 — 전각 이름과 한 줄이 카드의 것과 같다(같은 로케일 키).
  test "방 머리에 전각 이름과 한 줄이 있고, 카드의 것과 같다" do
    { new_sitting_path => :sitting, new_copying_path => :copying,
      days_path => :maitreya, guide_path => :lecture }.each do |path, key|
      get path

      assert_select ".hall-header__name", text: I18n.t("compound.halls.#{key}")
      assert_select ".hall-header__line", text: I18n.t("compound.detail.#{key}.line")
    end
  end

  # 채색본의 톤은 파일이 아니라 :root 의 네 값에서 온다. 그림 한 곳에만 걸려
  # 확대 장면에도 같은 톤이 따라가고, 값이 두 곳으로 흩어지지 않는다.
  test "경내 그림의 톤은 :root 네 값에서, 그림 한 곳에만 걸린다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    root = css[/:root \{.*?\n\}/m]

    %w[saturate sepia brightness contrast].each do |name|
      assert_match(/--compound-#{name}: [\d.]+;/, root, "--compound-#{name} 가 :root 에 없다")
      assert_equal 1, css.scan(/#{name}\(var\(--compound-#{name}\)\)/).size, "#{name} 이 한 곳이 아니다"
    end
    assert_match(/\.compound__map \{\s*filter: saturate\(var/, css)
    assert_no_match(/\.compound(--zooming)? (\.compound__scene )?\{[^}]*filter/, css, "톤이 그림 밖에 걸렸다")
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
