# This app is a raft. — 이 앱도 뗏목이다.
#
# 날들이 도는가 — 달력이 열리고, 적고 지우고, 비우고 거둔다. 깨지면 버그다.
# 날들이 어떻게 생겼는가는 자물쇠 쪽이다 — test/locks/form/days_form_test.rb.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class DaysFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one) # Asia/Seoul
    sign_in_as @user
  end

  test "달력이 열리고 날짜 숫자는 제자리에만 있다" do
    get days_path

    assert_response :success
    assert_select ".calendar .day .date"
    assert_no_match(/\d/, text_outside_dates, "달력 밖에 숫자가 있다")
  end

  test "적고 지운다 — 그것뿐이다" do
    assert_difference -> { @user.plans.count }, 1 do
      post plans_path, params: { plan: { planned_on: @user.today.iso8601, what: "치과" } }
    end

    follow_redirect!
    assert_match "치과", visible_text

    assert_difference -> { @user.plans.count }, -1 do
      delete plan_path(@user.plans.last)
    end
  end

  test "빈 줄로 적으면 조용히 넘기지 않고 한 줄로 까닭을 말한다" do
    assert_no_difference -> { @user.plans.count } do
      post plans_path, params: { plan: { planned_on: @user.today.iso8601, what: "   " } }
    end

    follow_redirect!
    assert_select ".flash", text: I18n.t("activerecord.errors.models.plan.attributes.what.blank")
  end

  test "너무 긴 줄도 까닭을 말한다" do
    post plans_path, params: { plan: { planned_on: @user.today.iso8601, what: "가" * (Plan::MOST + 1) } }
    follow_redirect!

    assert_select ".flash", text: I18n.t("activerecord.errors.models.plan.attributes.what.too_long")
  end

  test "미리 비워 둔 날은 달력에 옅은 원으로 남는다" do
    patch day_path(@user.today)
    follow_redirect!

    assert @user.clearings.exists?(cleared_on: @user.today)
    assert_match I18n.t("days.cleared"), visible_text

    get days_path
    assert_select ".calendar .clear"
  end

  test "비움은 언제든 거둘 수 있고, 거두어도 아무 일이 없다" do
    patch day_path(@user.today)

    assert_difference -> { @user.clearings.count }, -1 do
      patch day_path(@user.today)
    end
  end

  # 비움은 앱의 한가운데 행위다. 세 번 눌러 들어가야 닿을 일이 아니다.
  test "오늘 화면에서 오늘을 비우고 거둔다" do
    get today_path
    assert_select "form[action=?]", day_path(@user.today, from: "today")
    assert_match I18n.t("today.clear"), visible_text

    patch day_path(@user.today, from: "today")
    assert_redirected_to today_path
    assert @user.clearings.exists?(cleared_on: @user.today), "오늘이 비워지지 않았다"

    follow_redirect!
    assert_match I18n.t("today.unclear"), visible_text

    patch day_path(@user.today, from: "today")
    assert_empty @user.clearings.where(cleared_on: @user.today), "비움을 거두지 못한다"
  end

  # 비움은 사실의 보고가 아니라 선언이다. 일정이 있어도 비울 수 있다.
  test "일정이 있어도 오늘을 비울 수 있다" do
    @user.plans.create!(planned_on: @user.today, what: "회의")

    get today_path
    assert_match I18n.t("today.clear"), visible_text

    patch day_path(@user.today, from: "today")
    assert @user.clearings.exists?(cleared_on: @user.today)
  end

  # 다른 날의 비움은 그 날의 자리에 그대로 남는다.
  test "다른 날은 날들에서 비운다" do
    get day_path(@user.today - 3)

    assert_select "form[action=?]", day_path(@user.today - 3)
    patch day_path(@user.today - 3)

    assert_redirected_to day_path(@user.today - 3)
    assert @user.clearings.exists?(cleared_on: @user.today - 3)
  end

  test "달력은 하나뿐이고, 예전의 달 화면은 날들로 보낸다" do
    get "/ko/moon"

    assert_redirected_to "/ko/days"
    follow_redirect!

    assert_select "nav.doors a[href=?]", days_path, count: 1
    assert_select ".calendar", count: 1, message: "달력이 하나가 아니다"
    assert_select ".trail", false, "달의 자취가 따로 남아 있다"
  end

  private
    # 바쁜 저녁에 올 수 있는 말 전부 — 늘 하는 한마디와 무원의 세 줄.
    def evening_lines(locale = I18n.locale)
      [ I18n.t("days.evening", locale: locale) ] +
        Evening::WITHOUT_AIM.map { |name| I18n.t("days.without_aim.#{name}", locale: locale) }
    end

    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end

    # 날짜 숫자는 .date 안에만 있다. 그 밖의 숫자는 하나도 없어야 한다.
    def text_outside_dates
      page = Nokogiri::HTML(response.body)
      page.css(".date").each(&:remove)
      page.css("body").text.gsub(/\s+/, " ")
    end
end
