# This app is a raft. — 이 앱도 뗏목이다.
#
# 처음의 문 셋. 튜토리얼은 알려주는 것이고 리츄얼은 거치게 하는 것이다.
require "test_helper"

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

  # 서두를 수 없다는 것을 말로 하지 않고 실제로 기다리게 한다.
  test "첫째 문 — 한 줄뿐이고, 나아가는 길은 기다려야 나타난다" do
    get threshold_path

    assert_select ".threshold__line", count: 1
    assert_select "a[href=?][hidden][data-wait-target=reveal]", threshold_naming_path
    assert_operator css_select("[data-wait-after-value]").first["data-wait-after-value"].to_i, :>=, 3000
    assert_select "noscript a[href=?]", threshold_naming_path, message: "자바스크립트 없이는 영영 갇힌다"
  end

  # 설문이 아니다. 선택지도, 태그도, 분류도, 예시 문구도 없다.
  test "둘째 문 — 한 줄을 적는 자리 하나뿐이다" do
    get threshold_naming_path

    assert_select "input[type=text]", count: 1
    assert_select "select, option, datalist, input[type=radio], input[type=checkbox], textarea", false
    assert_select "input[placeholder]", false, "예시 문구가 답을 끌어간다"
  end

  test "적은 한 줄은 받아 두기만 한다" do
    patch threshold_naming_path, params: { user: { resting_from: "  끝나지 않는 메일에서  " } }

    assert_equal "끝나지 않는 메일에서", @user.reload.resting_from
    assert_redirected_to threshold_breath_path
  end

  test "비워 두고 지나갈 수 있다" do
    patch threshold_naming_path, params: { user: { resting_from: "" } }

    assert_nil @user.reload.resting_from
    assert_redirected_to threshold_breath_path
  end

  # 분석하지도, 추천에 쓰지도 않는다. 적은 줄을 읽는 곳을 못박는다.
  test "적은 한 줄은 정해진 곳 말고는 읽히지 않는다" do
    allowed = %w[app/controllers/onboarding_controller.rb app/models/export.rb app/models/user.rb
                 app/views/onboarding/naming.html.erb]
    readers = Rails.root.join("app").glob("**/*.{rb,erb,js}").select { |path| path.read.include?("resting_from") }

    assert_empty readers.map { |path| path.relative_path_from(Rails.root).to_s } - allowed,
      "「무엇에서 쉬려 하는가」를 다른 곳에서 읽는다"
  end

  test "셋째 문 — 손을 얹고 숨 세 번, 그러면 열린다" do
    get threshold_breath_path

    assert_select ".threshold--breath[data-controller=breath]"
    assert_select "form[action=?][data-breath-target=gate]", threshold_passed_path
    css = Rails.root.join("app/assets/tailwind/application.css").read
    assert_match(/\.threshold--breath\.breathing \{ animation: threshold-breath [\d.]+s ease-in-out 3; \}/, css,
      "숨이 세 번이 아니다")
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
    praise = /잘했|훌륭|대단|축하|멋지|well done|great|good job|congrat|nice|amazing/i

    %i[ko en].each do |locale|
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
end
