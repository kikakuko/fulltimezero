# This app is a raft. — 이 앱도 뗏목이다.
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

  test "나가며 묻는 자리에는 붙잡는 것이 없다" do
    post nothing_path
    patch sitting_path(@user.sittings.last)
    follow_redirect!

    assert_select "header.chrome", false, "나가는 길에 헤더가 남아 있다"
    assert_select ".locales", false
  end

  test "앉고 마치면 달이 그 날을 센다" do
    assert_difference -> { @user.sittings.count }, 1 do
      post sittings_path, params: { sitting: { length: "incense", bell: "1" } }
    end

    sitting = @user.sittings.last
    follow_redirect!

    assert_select ".night"
    assert_select ".night .moon"

    patch sitting_path(sitting)
    follow_redirect!

    assert_match I18n.t("sittings.done"), visible_text
    assert @user.reload.moon.days.last.rested?, "앉은 날이 달에 세어지지 않았다"
  end

  test "중간에 마쳐도 실패가 아니다 — 같은 화면, 같은 말" do
    post sittings_path, params: { sitting: { length: "long" } }
    sitting = @user.sittings.last

    patch sitting_path(sitting)
    follow_redirect!

    assert_match I18n.t("sittings.done"), visible_text
    assert_no_match(/실패|다시|아쉽/, visible_text)
  end

  test "앉음은 쉼으로 환산되지 않는다" do
    assert_no_difference -> { @user.rests.count } do
      post sittings_path, params: { sitting: { length: "tea" } }
      patch sitting_path(@user.sittings.last)
    end
  end

  test "무위에는 달이 없다 — 타이머의 어둠과 결이 다르다" do
    post nothing_path
    follow_redirect!

    assert_select ".void"
    assert_select ".void .moon", false, "무위에 달이 떠 있다"
    assert_select ".night", false
    assert_match I18n.t("nothing.line"), visible_text
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

  test "오늘 이미 고요했다면 물음이 조름이 되지 않는다" do
    get today_path
    assert_match I18n.t("today.question"), visible_text

    post nothing_path
    get today_path

    assert_match I18n.t("today.already_quiet"), visible_text
    assert_no_match(/#{I18n.t("today.question")}/, visible_text)
  end

  # 앉기의 자리에 두 길이 같은 무게로 선다. 무위를 2차 메뉴로 내려 두면
  # 그것은 곁가지가 된다.
  test "앉는다와 아무것도 하지 않는다가 나란히 선다" do
    get new_sitting_path

    assert_select ".ways button[form=sitting-form]", text: I18n.t("sittings.new.submit"), count: 1
    assert_select ".ways button[form=nothing-form]", text: I18n.t("sittings.new.nothing"), count: 1
    assert_select "form#sitting-form[action=?]", sittings_path, count: 1
    assert_select "form#nothing-form[action=?]", nothing_path, count: 1
    assert_select ".ways button.button-primary", count: 2, message: "두 길이 같은 먹 알약이 아니다"
  end

  # 톤 정비 — 앉기의 부품. 산수는 먹틀에, 두 길은 먹 알약 둘, 나오는 길은 조용한 버튼.
  test "앉기는 부품 다섯으로 선다 — 옛 버튼 없이" do
    get new_sitting_path
    assert_select ".elephant-field.ink-frame", count: 1
    assert_select ".button-primary", count: 2
    assert_select ".verse", false

    post sittings_path, params: { sitting: { length: SittingLength::DEFAULT } }
    follow_redirect!
    assert_select ".night .leave button.button-quiet", count: 1

    post nothing_path
    follow_redirect!
    assert_select ".void .leave button.button-quiet", count: 1
    patch sitting_path(Sitting.order(:id).last)
    follow_redirect!
    assert_select "a.button-primary", count: 1
    assert_select "a.button-quiet", count: 1
  end

  private
    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end
end
