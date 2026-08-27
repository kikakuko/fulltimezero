# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

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

  test "일정을 아무리 쌓아도 개수는 어디에도 나타나지 않는다" do
    %w[치과 회의 저녁 약속 장보기 전화].each do |what|
      @user.plans.create!(planned_on: @user.today, what: what)
    end

    get day_path(@user.today)
    assert_no_match(/\d/, text_outside_dates, "하루 화면에 숫자가 보인다")

    get days_path
    assert_no_match(/\d/, text_outside_dates, "달력에 개수가 보인다")
    assert_select ".calendar .kept", count: 1, message: "먹점은 날마다 하나뿐이다"
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

  test "오늘이 비어 있으면 축하한다" do
    get today_path

    assert_match I18n.t("days.empty_today"), visible_text
  end

  test "바쁜 날에는 낮 내내 아무 말도 하지 않는다" do
    @user.plans.create!(planned_on: @user.today, what: "회의")

    travel_to Time.utc(2026, 8, 27, 4, 0) do # 서울 낮 한시
      get today_path

      assert_no_match I18n.t("days.evening"), visible_text
      assert_no_match I18n.t("days.empty_today"), visible_text
    end
  end

  test "저녁에야 한마디 한다" do
    travel_to Time.utc(2026, 8, 27, 11, 0) do # 서울 저녁 여덟시
      @user.plans.create!(planned_on: @user.today, what: "회의")
      get today_path

      assert_match I18n.t("days.evening"), visible_text
    end
  end

  # 빈 날의 축하가 바쁜 날의 비난이 되어서는 안 된다(제5조).
  test "축하와 위로는 서로의 거울이 아니다" do
    %i[ko en].each do |locale|
      busy = I18n.t("days.evening", locale: locale)

      assert_no_match(/못|실패|아쉽|부족|failed|should have|too much/i, busy,
        "#{locale} 의 저녁 문구가 나무란다: #{busy}")
    end
  end

  test "비운 날 아침에만 달이 한 번 크게 숨 쉰다" do
    travel_to Time.utc(2026, 8, 26, 22, 0) do # 서울 아침 일곱시
      get today_path
      assert_select ".cleared", message: "비운 날 아침인데 달이 조용하다"

      get today_path
      assert_select ".cleared", false, "같은 아침에 두 번 숨 쉰다"
    end
  end

  test "바쁜 아침에는 숨 쉬지 않는다" do
    travel_to Time.utc(2026, 8, 26, 22, 0) do
      @user.plans.create!(planned_on: @user.today, what: "회의")
      get today_path

      assert_select ".cleared", false
    end
  end

  test "날들은 어떤 알림도 보내지 않는다" do
    assert_no_enqueued_emails do
      post plans_path, params: { plan: { planned_on: @user.today.iso8601, what: "회의" } }
      patch day_path(@user.today)
      get days_path
      get today_path
    end
  end

  private
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
