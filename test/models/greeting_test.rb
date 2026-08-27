# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class GreetingTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "같은 날 같은 사람에게는 늘 같은 말이 온다 — 인사지 뽑기가 아니다" do
    year = (Date.new(2026, 1, 1)..Date.new(2026, 12, 31))
    speaking = year.find { |date| Greeting.for(@user, on: date) }

    assert speaking, "한 해 내내 아무 말도 하지 않는다"
    3.times { assert_equal Greeting.for(@user, on: speaking), Greeting.for(@user, on: speaking) }
  end

  test "말이 오지 않는 날이 대부분이다" do
    year = (Date.new(2026, 1, 1)..Date.new(2026, 12, 31))

    silent = year.count { |date| Greeting.for(@user, on: date).nil? }

    assert_operator silent, :>, year.count * 0.6,
      "말이 잦다. 대부분의 날은 아무 말도 없어야 한다."
  end

  test "매일 있지 않다. 이레에 한두 번쯤이다" do
    year = (Date.new(2026, 1, 1)..Date.new(2026, 12, 31))
    spoken = year.count { |date| Greeting.for(@user, on: date) }

    weekly = spoken / 52.0

    assert_operator weekly, :>=, 0.5, "인사가 너무 드물다"
    assert_operator weekly, :<=, 2.5, "인사가 잦다. 매일 있으면 반갑지 않다."
  end

  test "고른 말은 그 계절이나 그 요일의 것이다" do
    sunday = Date.new(2026, 8, 30)

    assert_includes Greeting.keys_for(sunday), "sunday"
    assert_includes Greeting.keys_for(sunday), "deep_summer"
    assert_includes Greeting.keys_for(Date.new(2026, 12, 28)), "year_end"
    assert_includes Greeting.keys_for(Date.new(2026, 1, 3)), "new_year"
  end

  test "어느 날에 오는 말이든 ko/en 양쪽에 있다" do
    (Date.new(2026, 1, 1)..Date.new(2026, 12, 31)).each do |date|
      Greeting.keys_for(date).each do |key|
        %i[ko en].each do |locale|
          assert I18n.exists?("greetings.#{key}", locale),
            "#{locale} 에 greetings.#{key} 가 없다"
        end
      end
    end
  end

  test "인사에도 느낌표와 이모지가 없다" do
    %i[ko en].each do |locale|
      I18n.t("greetings", locale: locale).each_value do |line|
        assert_no_match(/[!\u{1F300}-\u{1FAFF}]/, line, line)
      end
    end
  end
end
