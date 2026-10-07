# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉기가 도는가 — 앉고 마치면 달이 그 날을 세고, 무위에 들고 나는 길이 열린다. 깨지면 버그다.
# 앉기가 어떻게 생겼는가는 자물쇠 쪽이다 — test/locks/form/sitting_form_test.rb.
require "test_helper"

class SittingFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "오늘 화면에서 앉는 자리로 갈 수 있다" do
    get today_path

    assert_select "a[href=?]", new_sitting_path
  end

  test "앉고 마치면 달이 그 날을 세고, 코끼리가 그 시간을 받는다" do
    assert_difference -> { @user.sittings.count }, 1 do
      post sittings_path, params: { sitting: { length: "incense", bell: "1" } }
    end

    sitting = @user.sittings.last
    follow_redirect!

    assert_select ".night"
    assert_select ".night .moon", false, "앉는 동안 달이 떠 있다"
    assert_select ".night .elephant-field", count: 1, message: "앉는 동안 길이 없다"

    # 향 한 대만큼 앉았다 치고 마친다 — 코끼리는 앉은 시간을 받는다.
    before = Elephant.for(@user).whiteness
    sitting.update!(created_at: 20.minutes.ago)
    patch sitting_path(sitting)
    follow_redirect!

    assert_match I18n.t("sittings.done"), visible_text
    assert_select ".moon", count: 1, message: "앉고 난 뒤에 그날의 달이 없다"
    assert @user.reload.moon.days.last.rested?, "앉은 날이 달에 세어지지 않았다"
    assert_operator Elephant.for(@user).whiteness, :>, before, "앉음이 끝났는데 코끼리가 그대로다"
  end

  test "중간에 마쳐도 실패가 아니다 — 같은 화면, 같은 말" do
    post sittings_path, params: { sitting: { length: "long" } }
    sitting = @user.sittings.last

    patch sitting_path(sitting)
    follow_redirect!

    assert_match I18n.t("sittings.done"), visible_text
    assert_no_match(/실패|다시|아쉽/, visible_text)
  end

  test "무위도 그 날을 센다" do
    post nothing_path

    assert @user.reload.moon.days.last.rested?
  end

  test "무위에서 나가면 한 번만 묻고 다시 붙잡지 않는다" do
    post nothing_path
    sitting = @user.sittings.last

    patch sitting_path(sitting)
    follow_redirect!
    assert_match I18n.t("nothing.keep_question"), visible_text

    # 같은 자리를 다시 열어도 물음은 되풀이되지 않는다.
    get sitting_path(sitting)
    assert_redirected_to today_path
  end

  test "무위를 쉼으로 남기면 「시간을 잊었다」가 미리 골라져 있다" do
    get new_rest_path(duration: "time_fell_away")

    assert_select "input[name='rest[duration]'][value=time_fell_away][checked]"
  end

  test "그냥 나가면 흔적이 남지 않는다" do
    post nothing_path

    assert_no_difference -> { @user.rests.count } do
      patch sitting_path(@user.sittings.last)
      get today_path
    end
  end

  private
    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end
end
