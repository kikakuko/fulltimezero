# This app is a raft. — 이 앱도 뗏목이다.
#
# 인사의 결 — 느낌표도 이모지도 없다.
require "test_helper"

class GreetingFormTest < ActiveSupport::TestCase
  setup { @user = users(:one) }


  test "인사에도 느낌표와 이모지가 없다" do
    I18n.available_locales.each do |locale|
      I18n.t("greetings", locale: locale).each_value do |line|
        assert_no_match(/[!\u{1F300}-\u{1FAFF}]/, line, line)
      end
    end
  end
end
