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
    travel_to Time.utc(2026, 8, 27, 4, 0) do # 서울 낮 한시
      # 일정은 여행한 그 날에 있어야 한다. 밖에서 만들면 다른 날의 일이다.
      @user.plans.create!(planned_on: @user.today, what: "회의")
      get today_path

      evening_lines.each { |line| assert_no_match line, visible_text }
      assert_no_match I18n.t("days.empty_today"), visible_text
    end
  end

  test "저녁에야 한마디 한다" do
    travel_to Time.utc(2026, 8, 27, 11, 0) do # 서울 저녁 여덟시
      @user.plans.create!(planned_on: @user.today, what: "회의")
      get today_path

      assert evening_lines.any? { |line| visible_text.include?(line) }, "저녁에 아무 말도 없다"
    end
  end

  # 무원(無願) — 바라는 바 없음. 응원이 아니라 서술이다. 이레에 한두 번,
  # 계절 인사와 같은 빈도로 온다. 온기는 빈도가 낮을수록 진하다.
  test "바쁜 저녁에 이레에 한두 번 무원의 줄이 온다" do
    days = (0..139).map { |i| Evening.line_for(@user, on: Date.new(2026, 1, 1) + i) }
    without_aim = days.count { |line| line != Evening::USUAL }

    assert_includes 1..2, (without_aim / 140.0 * 7).round, "무원의 줄이 흔하거나 드물다"
    assert_equal Evening::WITHOUT_AIM.size, days.uniq.size - 1, "세 줄이 고루 오지 않는다"
  end

  test "같은 날에는 늘 같은 줄이 온다 — 새로고침은 뽑기가 아니다" do
    days = (0..29).map { |i| Date.new(2026, 3, 1) + i }

    assert_equal days.map { |day| Evening.line_for(@user, on: day) },
                 days.map { |day| Evening.line_for(@user, on: day) }
    assert_not_equal days.map { |day| Evening.line_for(@user, on: day) },
                     days.map { |day| Evening.line_for(users(:two), on: day) },
                     "사람이 달라도 같은 날에 같은 줄이 온다"
  end

  # 「바라는 바 없이 한다」를 「바라지 말라」로 바꾸면 명령이 된다.
  test "저녁의 말은 응원도 명령도 아니다" do
    orders = /하자$|해보|해\s?봐|하세요|하십시오|하라$|해라$|합시다|\b(?:let'?s|try|keep going|you can do)\b/i

    %i[ko en].each do |locale|
      Evening::WITHOUT_AIM.each do |name|
        line = I18n.t("days.without_aim.#{name}", locale: locale)

        assert_no_match orders, line, "#{locale} 의 저녁 줄이 시킨다: #{line}"
        assert_empty CopyLocks.breaks(line), "#{locale} 의 저녁 줄이 자물쇠에 걸린다: #{line}"
      end
    end
  end

  # 빈 날의 축하가 바쁜 날의 비난이 되어서는 안 된다(제5조).
  test "축하와 위로는 서로의 거울이 아니다" do
    %i[ko en].each do |locale|
      evening_lines(locale).each do |busy|
        assert_no_match(/못|실패|아쉽|부족|failed|should have|too much/i, busy,
          "#{locale} 의 저녁 문구가 나무란다: #{busy}")
      end
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
