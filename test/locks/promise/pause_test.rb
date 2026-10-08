# This app is a raft. — 이 앱도 뗏목이다.
#
# 틈은 묻지 않는다 — 마당의 낙관 「쉼」을 누르면 길이도 결도 묻지 않고 바로 남는다.
# 묻기 시작하면 「틈틈이」가 아니다. 길이와 결을 적는 자리는 미륵당의 하루에만 있다.
# 틈은 세지 않는다 — 몇 번인지 보여 주는 곳이 없다(§3). 기록이지 횟수가 아니다.
require "test_helper"

class PauseTest < ActionDispatch::IntegrationTest
  include Screens

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "마당의 쉼 기록에는 길이도 결도 입력이 없다" do
    get today_path

    assert_select "form#rest[action=?]", rests_path, count: 1
    assert_select "form#rest button.seal.rested", count: 1
    assert_select "form#rest input:not([type=hidden])", false, "마당의 낙관이 무언가를 묻는다"
    assert_select "form#rest select, form#rest textarea", false, "마당의 낙관이 무언가를 묻는다"
    assert_select "form#rest input[name^='rest[']", false, "마당의 낙관이 길이나 결을 보낸다"
    assert_select "a[href=?]", new_rest_path, false, "마당에서 길이를 적는 자리로 간다"
  end

  test "틈을 세어 보여 주는 곳이 없다" do
    3.times { @user.rests.create!(without_asking: true) }

    [ today_path, days_path, day_path(@user.today), settings_path ].each do |screen|
      get screen
      assert_no_match(/틈\s*(?:[0-9]+|[두세네]|\w+ 번)/, visible_text, "#{screen} 에서 틈을 센다")
    end
    get day_path(@user.today)
    assert_select ".plans li", text: /#{I18n.t("rests.pause")}/, count: 3
  end

  test "손님에게는 낙관이 보이되 누르면 구경하는 자리 한 줄이다" do
    reset!
    User.create!(email_address: Guest::SEED, password: SecureRandom.hex(16),
                 onboarded_at: 60.days.ago, locale: "ko", time_zone: "Asia/Seoul")
    was = ENV["SIGNUPS"]
    ENV["SIGNUPS"] = "false"

    get today_path
    assert_select "a.seal.rested[href=?]", new_rest_path, count: 1
    assert_select "form#rest", false, "손님에게 보내는 손짓이 있다"

    get new_rest_path
    assert_match I18n.t("guest.only_looking"), visible_text
  ensure
    ENV["SIGNUPS"] = was
  end
end
