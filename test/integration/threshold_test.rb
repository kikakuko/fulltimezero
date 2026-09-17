# This app is a raft. — 이 앱도 뗏목이다.
#
# 처음의 문 셋. 튜토리얼은 알려주는 것이고 리츄얼은 거치게 하는 것이다.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class ThresholdTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(onboarded_at: nil)
    sign_in_as @user
  end

  test "문 앞의 사람은 오늘에 앞서 첫째 문으로 간다" do
    get today_path

    assert_redirected_to threshold_path
  end

  # 빛이 다가와 한 번 넘치고 가라앉으면 한 줄, 한 박 뒤 경의 한 줄과 출전,
  # 그 뒤 길. 순서는 CSS 의 늦춤뿐이다 — 스크립트가 붙잡고 기다리게 하지 않고,
  # 길은 처음부터 문서 안에 있다.
  test "첫째 문 — 빛이 가라앉은 뒤 한 줄, 경의 한 줄, 그 뒤 길" do
    get threshold_path

    assert_select ".gates__line", count: 1, text: I18n.t("threshold.stop.line")
    assert_select "a[href=?]:not([hidden])", threshold_naming_path
    assert_select "[data-wait-after-value], [data-controller~=wait]", false, "첫째 문이 스크립트로 기다리게 한다"

    css = Rails.root.join("app/assets/tailwind/application.css").read
    line = css[/\.threshold--stop \.gates__line \{ animation: gate-word [\d.]+s ease-out var\(--light-arrive\) both; \}/]
    quote = css[/\.threshold--stop \.threshold__quote \{ animation: gate-word [\d.]+s ease-out calc\(var\(--light-arrive\) \+ 1s\) both; \}/]
    way = css[/\.threshold--stop \.threshold__way \{ animation: gate-word [\d.]+s ease-out calc\(var\(--light-arrive\) \+ ([\d.]+)s\) both; \}/]
    assert line, "한 줄이 빛이 가라앉기를 기다리지 않는다"
    assert quote, "경의 한 줄이 한 박 뒤가 아니다"
    assert way && $1.to_f > 1, "길이 경의 한 줄보다 먼저 온다"
    assert_match(/\.threshold--stop \.threshold__later \{ animation: gate-later /, css)
    assert_match(/@keyframes gate-later \{ from \{ opacity: 0\.2; \}/, css, "「나중에」가 빛이 닿기 전에 눈에 띈다")
  end

  # 『앙굴리말라경』의 「나는 멈추었다」 — 선언이지 명령이 아니다. 앱이
  # 사용자에게 멈추라고 하지 않는다. 읽는 사람이 스스로 옮겨 오게 둔다.
  test "문의 세 줄 — 멈추었다, 무엇이 움직이는가, 한 번도 움직인 적 없다" do
    { threshold_path => "threshold.stop.line", threshold_naming_path => "threshold.naming.question",
      threshold_breath_path => "threshold.breath.line" }.each do |door, key|
      get door
      assert_select ".gates__line", text: I18n.t(key)
    end

    I18n.available_locales.each do |locale|
      # 경의 한 줄(quote)은 앱의 말이 아니다 — 인용 부품의 자물쇠(verse_test)가 출전과 함께만 서게 지킨다.
      doors = I18n.t("threshold", locale: locale).transform_values { |value| value.is_a?(Hash) ? value.except(:quote) : value }
      lines = doors.values.flat_map { |value| value.is_a?(Hash) ? value.values : value }.join("\n")
      assert_no_match(/멈추어라|멈춰라|멈추세요|\bstop(?! ?ped)\b/i, lines, "문이 사용자에게 멈추라고 한다")
      assert_no_match(/문 앞에 섰다|무엇에서 쉬려|화면에 손을 얹는다|come to the gate|resting from|Rest your hand/, lines)
    end
  end

  # 그림은 절대 움직이지 않는다. 사용자가 다가가는 것이 아니라 보이지
  # 않던 것이 드러날 뿐이다 — 한 번도 움직인 적 없다는 것이 화면의
  # 동작으로도 지켜져야 한다. 바뀌는 것은 장막뿐이다.
  test "그림은 움직이지 않는다 — 스크롤도 확대도 카메라 이동도 없다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read.gsub(%r{/\*.*?\*/}m, "")
    # 선택자가 가리키는 것(마지막 대상)이 그림 · 그 틀 · 문 전체일 때만 본다.
    # 그 위에 얹히는 빛과 넘침은 그림이 아니다.
    still = css.scan(/([^{}]+)\{([^{}]*)\}/).select do |selector, _|
      selector.split(",").any? { |one| one.strip.split(/\s+/).last.to_s.match?(/\A\.gates(?:__image|__frame)?(?![\w-])/) }
    end

    assert_not_empty still
    still.each do |selector, body|
      assert_no_match(/transform|translate|scale|rotate|zoom|animation|background-position|object-position|overflow:\s*(?:auto|scroll)/,
                      body, "그림이 움직인다: #{selector.strip}")
      # 옅어지는 것은 움직임이 아니다. 옮아감은 불투명도 하나뿐이다.
      body.scan(/transition:\s*([^;]+)/).flatten.each do |transition|
        assert_match(/\A(?:none|opacity\b[^,]*)\z/, transition.strip, "그림이 움직인다: #{selector.strip}")
      end
    end

    scripts = Rails.root.glob("app/javascript/**/*.js").select { |path| path.read.include?("gates__image") }
    assert_empty scripts, "스크립트가 그림에 손을 댄다"
  end

  # 아이폰의 사파리는 글자가 16px 보다 작은 입력칸을 누르면 화면을 확대한다.
  # 그것도 카메라 이동이다.
  test "둘째 문의 입력칸을 눌러도 화면이 확대되지 않는다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    size = css[/\.threshold__field \{[^}]*font-size: ([\d.]+)rem/m, 1]

    assert size, "입력칸의 글자 크기가 정해져 있지 않다"
    assert_operator size.to_f, :>=, 1.0, "입력칸의 글자가 16px 보다 작다"
  end

  # 장막은 위 삼분의 일에만, 반을 넘지 않게. 아래는 그림 그대로다.
  test "장막은 위 삼분의 일만 옅게 덮고, 아래는 그림 그대로다" do
    css = Rails.root.join("app/assets/tailwind/application.css").read.gsub(%r{/\*.*?\*/}m, "")
    stops = css.match(/--veil-stop-top: ([\d.]+);.*?--veil-stop-upper: ([\d.]+);/m).captures.map(&:to_f)
    assert stops.all? { |value| value <= 0.5 }, "첫째 문의 장막이 반을 넘는다"

    %w[stop naming breath].each do |state|
      rule = css[/\.gates__veil\[data-state="#{state}"\][^{]*\{([^}]*)\}/, 1]
      alphas = rule.scan(/--veil-a\d: (?:var\(--veil-stop-\w+\)|([\d.]+))/).flatten.compact.map(&:to_f)
      assert alphas.all? { |value| value <= 0.5 }, "#{state} 의 장막이 반을 넘는다"
      assert_operator rule[/--veil-p4: (\d+)%/, 1].to_i, :<=, 34, "#{state} 의 장막이 위 삼분의 일을 넘어 내려온다"
      assert_equal 0.0, rule[/--veil-r3: ([\d.]+)/, 1].to_f, "#{state} 에 둘레를 잠그는 어둠이 있다"
    end

    scrim = css[/\.gates__scrim \{[^}]*\}/]
    assert_no_match(/night/, scrim, "아래에 어둠의 그늘이 남아 있다")
  end

  test "그림은 자르지 않고 통째로 — 틀이 그림의 비율 그대로다" do
    image = Rails.root.join("app/assets/images/gates.png")
    assert image.exist?, "그림(gates.png)이 아직 없다"

    width, height = image.binread(24).unpack("x16NN")
    css = Rails.root.join("app/assets/tailwind/application.css").read
    frame = css[/--gates-w: min\(100vw, calc\(100svh \* (\d+) \/ (\d+)\)\)/] && [ $1.to_i, $2.to_i ]

    assert_equal Rational(width, height), Rational(*frame), "틀의 비율이 그림과 다르다"
    assert_match(/\.gates__image \{[^}]*object-fit: contain/, css, "그림을 잘라 채운다")
  end

  test "그림과 장막은 문을 옮겨 가는 동안 그대로 남고, 장막만 상태를 바꾼다" do
    { threshold_path => "stop", threshold_naming_path => "naming", threshold_breath_path => "breath" }.each do |door, state|
      get door

      assert_select "#gates[data-turbo-permanent] .gates__frame img.gates__image[alt='']"
      assert_select "#gates .gates__veil[data-state=?]", state
      assert_select "#gates .gates__scrim"
      assert_select ".threshold[data-controller~=gates][data-gates-state-value=?]", state
    end

    css = Rails.root.join("app/assets/tailwind/application.css").read
    %w[stop naming breath open].each { |state| assert_match(/\.gates__veil\[data-state="#{state}"\]/, css) }
    assert_match(/--veil-a1 1\.2s ease-out/, css, "상태 사이의 옮아감이 1.2초가 아니다")
    assert_match(/\.gates__veil\[data-state="open"\] \{ opacity: 0; transition: opacity 1\.6s ease-out; \}/, css)
    assert_match(/prefers-reduced-motion: reduce\) \{\s*\.gates__veil[^{]*\{ transition: none; \}/, css,
                 "움직임을 줄인 화면에서도 옮아간다")
  end

  # 설문이 아니다. 선택지도, 태그도, 분류도, 예시 문구도 없다.
  test "둘째 문 — 한 줄을 적는 자리 하나뿐이다" do
    get threshold_naming_path

    assert_select "input[type=text]", count: 1
    assert_select "select, option, datalist, input[type=radio], input[type=checkbox], textarea", false
    assert_select "input[placeholder]", false, "예시 문구가 답을 끌어간다"
  end

  test "적은 한 줄은 받아 두기만 한다" do
    patch threshold_naming_path, params: { user: { what_moves: "  끝나지 않는 생각  " } }

    assert_equal "끝나지 않는 생각", @user.reload.what_moves
    assert_redirected_to threshold_breath_path
  end

  test "비워 두고 지나갈 수 있다" do
    patch threshold_naming_path, params: { user: { what_moves: "" } }

    assert_nil @user.reload.what_moves
    assert_redirected_to threshold_breath_path
  end

  # 분석하지도, 추천에 쓰지도 않는다. 적은 줄을 읽는 곳을 못박는다.
  test "적은 한 줄은 정해진 곳 말고는 읽히지 않는다" do
    # 가입 때 세션에서 계정으로 옮기는 곳(users_controller)도 읽는 곳이다.
    allowed = %w[app/controllers/onboarding_controller.rb app/controllers/users_controller.rb
                 app/models/export.rb app/models/user.rb app/views/onboarding/naming.html.erb]
    readers = Rails.root.join("app").glob("**/*.{rb,erb,js}").select { |path| path.read.include?("what_moves") }

    assert_empty readers.map { |path| path.relative_path_from(Rails.root).to_s } - allowed,
      "둘째 문에 적은 한 줄을 다른 곳에서 읽는다"
  end

  # 할 일이 없다. 한 줄이 떠 있고, 아무것도 하지 않아도 잠시 뒤 장막이 스스로
  # 걷힌다. 버튼도 손도 없다.
  test "셋째 문 — 아무것도 하지 않아도 잠시 뒤 장막이 스스로 걷힌다" do
    get threshold_breath_path

    assert_select ".threshold--breath[data-controller~=breath]"
    assert_select ".gates__line", count: 1, text: I18n.t("threshold.breath.line")
    assert_select "form[action=?][data-breath-target=gate]", threshold_passed_path
    assert_select ".threshold--breath[data-action]", false, "손을 얹게 한다"
    assert_select ".gates__hint", false, "손을 얹으라는 안내가 남아 있다"
    assert_select ".threshold--breath button, .threshold--breath a", count: 1, message: "「나중에」 말고 누를 것이 있다"

    breath = Rails.root.join("app/javascript/controllers/breath_controller.js").read
    dwell = breath[/const DWELL = (\d+)/, 1].to_i
    assert_includes 4000..5000, dwell, "떠 있는 동안이 넉 초에서 다섯 초 사이가 아니다"
    assert_match(/connect\(\) \{\s*this\.timer = setTimeout\(\(\) => this\.open\(\), DWELL\)/, breath, "스스로 걷히지 않는다")
    assert_no_match(/pointer|breath|hold\(|release\(/, breath, "손이 남아 있다")

    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_no_match(/gates-breath|gates--breathing/, css, "세 숨이 남아 있다")
  end

  test "문이 열리면 오늘 화면으로 가고, 다시 붙잡지 않는다" do
    post threshold_passed_path

    assert @user.reload.onboarded?
    assert_redirected_to today_path
    get today_path
    assert_response :success
  end

  test "어느 문에서든 「나중에」로 지나갈 수 있다" do
    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door
      assert_select "form[action=?] button", threshold_passed_path, text: I18n.t("threshold.later")
    end
  end

  test "문을 다시 지나도 처음 지난 날은 바뀌지 않는다" do
    post threshold_passed_path
    first = @user.reload.onboarded_at

    travel 3.days { post threshold_passed_path }

    assert_equal first.to_i, @user.reload.onboarded_at.to_i
  end

  # 잘했다는 말을 하지 않는다. 그냥 열린다.
  test "문에는 칭찬이 없고, 숫자도 없다" do
    praise = CopyLocks.pattern(:praise)

    I18n.available_locales.each do |locale|
      [ threshold_path(locale: locale), threshold_naming_path(locale: locale), threshold_breath_path(locale: locale) ].each do |door|
        get door
        text = Nokogiri::HTML(response.body).css("body").text

        assert_no_match praise, text, "#{door} 가 칭찬한다"
        assert_no_match(/\d/, text, "#{door} 에 숫자가 있다")
      end
    end
  end

  test "문 위에는 아래의 문 넷도 머리말도 없다" do
    get threshold_path

    assert_select "nav.doors", false
    assert_select "header.chrome", false
  end
  # 문은 가입보다 먼저다. 처음 온 사람은 계정 없이 문 셋을 지나고, 셋째 문
  # 뒤에 가입한다. 둘째 문의 답은 세션이 들고 있다가 계정으로 옮긴다.
  test "처음 온 사람은 앱을 열면 바로 첫째 문 앞에 선다" do
    sign_out
    get gate_path

    assert_redirected_to threshold_path
    follow_redirect!
    assert_select ".gates__line", text: I18n.t("threshold.stop.line")
    assert_select "nav.doors", false
  end

  test "들어온 사람은 앱을 열면 마당으로 간다" do
    @user.update!(onboarded_at: Time.current)
    get gate_path

    assert_redirected_to today_path
  end

  test "계정 없이 문 셋을 지나고, 셋째 문 뒤에 가입한다" do
    sign_out

    [ threshold_path, threshold_naming_path, threshold_breath_path ].each do |door|
      get door
      assert_response :success, "#{door} 가 계정 없이 열리지 않는다"
    end

    patch threshold_naming_path, params: { user: { what_moves: "  끝나지 않는 생각  " } }
    assert_redirected_to threshold_breath_path

    post threshold_passed_path
    assert_redirected_to new_user_path
    follow_redirect!
    assert_match I18n.t("gate.line"), Nokogiri::HTML(response.body).css("main").text, "가입 화면에 그 한 줄이 없다"

    post users_path, params: { user: { email_address: "walked@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    user = User.find_by!(email_address: "walked@fulltimezero.test")

    assert user.onboarded?, "문을 지났는데 가입 뒤에 다시 문 앞이다"
    assert_equal "끝나지 않는 생각", user.what_moves, "둘째 문의 답이 계정에 옮겨지지 않았다"
    assert_redirected_to today_path
    follow_redirect!
    assert_response :success
  end

  test "가입 없이 나가면 둘째 문의 답은 버려진다" do
    sign_out
    patch threshold_naming_path, params: { user: { what_moves: "잊힐 한 줄" } }

    assert_empty User.where(what_moves: "잊힐 한 줄")
    reset!

    post users_path, params: { user: { email_address: "fresh@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    fresh = User.find_by!(email_address: "fresh@fulltimezero.test")
    assert_nil fresh.what_moves
    refute fresh.onboarded?, "문을 지나지 않았는데 지난 것으로 되어 있다"
  end

  test "문을 지나지 않고 가입한 사람은 마당에 앞서 문으로 간다" do
    sign_out
    post users_path, params: { user: { email_address: "direct@fulltimezero.test", password: "a good long password", time_zone: "Asia/Seoul" } }
    follow_redirect!

    assert_redirected_to threshold_path
  end
end
