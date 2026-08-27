# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class RestFlowTest < ActionDispatch::IntegrationTest
  test "가입하고 쉼을 기록하면 달이 차고 오늘 몫이 끝난다" do
    post users_path(locale: :ko), params: { user: {
      email_address: " NEW@Example.com ",
      password: "a good long password",
      password_confirmation: "a good long password",
      time_zone: "Asia/Seoul"
    } }

    user = User.find_by(email_address: "new@example.com")
    assert user, "가입되지 않았다"
    assert_equal "ko", user.locale
    assert_equal "Asia/Seoul", user.time_zone
    assert_redirected_to today_path(locale: :ko)

    follow_redirect!
    assert_response :success
    assert_select ".lead", text: I18n.t("today.question", locale: :ko)
    assert_select "a.action", text: I18n.t("today.rested", locale: :ko)

    get new_rest_path(locale: :ko)
    assert_response :success
    assert_select "input[type=radio][name='rest[duration]']", count: Rest::DURATIONS.size
    assert_select "input[type=radio][name='rest[texture]']", count: Rest::TEXTURES.size

    assert_difference -> { user.rests.count }, 1 do
      post rests_path(locale: :ko), params: { rest: { duration: "time_fell_away", texture: "" } }
    end
    assert_redirected_to today_path(locale: :ko)

    rest = user.rests.sole
    assert_equal "time_fell_away", rest.duration
    assert_nil rest.texture

    follow_redirect!
    assert_select ".flash", text: I18n.t("rests.recorded", locale: :ko)
    assert_select ".lead", text: I18n.t("today.done", locale: :ko)
    assert_select "a.action", count: 0, message: "오늘 몫이 끝난 화면에는 행동이 없어야 한다"
  end

  test "결을 고르지 않아도 기록된다" do
    sign_in_as users(:one)

    assert_difference -> { Rest.count }, 1 do
      post rests_path(locale: :ko), params: { rest: { duration: "one_breath" } }
    end
    assert_nil Rest.last.texture
  end

  test "길이를 고르지 않으면 기록되지 않는다" do
    sign_in_as users(:one)

    assert_no_difference -> { Rest.count } do
      post rests_path(locale: :ko), params: { rest: { texture: "walked" } }
    end
    assert_response :unprocessable_entity
  end

  test "미로그인은 문으로 돌려보낸다" do
    get today_path(locale: :en)
    assert_redirected_to new_session_path(locale: :en)
  end

  test "문은 로그인한 사람을 오늘로 보낸다" do
    sign_in_as users(:one)
    get gate_path(locale: :ko)
    assert_redirected_to today_path(locale: :ko)
  end
end
