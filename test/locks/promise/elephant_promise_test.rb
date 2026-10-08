# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 약속 둘.
#
#   **아홉 자리와 잇지 않는다** — 코끼리는 몸이고 아홉 자리는 안내다. 이으면 앱이
#   「당신은 다섯째요」라고 말하게 된다(§5).
#
#   **흰빛은 줄지 않는다** — 코끼리는 선방의 몸이라 지나간 앉음을 잃지 않는다.
#   잊음은 달의 것이다(§2, 2026-10-08). 사용자가 제 기록을 지우는 것은 제 손이라
#   다른 일이고, 그 밖의 어떤 길로도 내려가지 않는다.
#
# 흰빛의 값과 결은 결 쪽이다 — test/locks/form/elephant_white_test.rb.
require "test_helper"

class ElephantPromiseTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.rests.destroy_all
    @user.sittings.destroy_all
    @user.clearings.destroy_all
    @user.copyings.destroy_all
    @today = @user.today
  end

  # 코끼리는 흔적이고 아홉 자리는 안내다. 둘을 잇는 코드는 있을 수 없다.
  test "아홉 자리와 잇지 않는다" do
    elephant = Rails.root.join("app/models/elephant.rb").read
    assert_no_match(/abiding/i, elephant, "코끼리가 자리를 읽는다")

    # 코끼리 모델(Elephant · @elephant)과 자리가 한 줄에 함께 서면 잇는 것이다.
    # 정거장 이름의 링크(elephant-field__stop)는 CSS 이름이지 코끼리의 자리가 아니다.
    sources = Rails.root.glob("app/**/*.{rb,erb,js}").map(&:read).join
    assert_no_match(/abiding[^\n]*(?:\bElephant\b|@elephant\b)|(?:\bElephant\b|@elephant\b)[^\n]*abiding/, sources,
      "코끼리의 자리와 골라 둔 자리를 한 줄에서 잇는다")
    assert_no_match(/station[^\n]*abiding_id|abiding_id[^\n]*station|whiteness[^\n]*abiding/i, sources)
  end

  # 날이 흘러도, 쉼 · 비움 · 사경이 늘거나 줄어도 흰빛은 그대로다. 오르기만 한다.
  test "흰빛은 줄지 않는다 — 날이 흘러도, 다른 것이 바뀌어도" do
    sit(minutes: 90, on: @today - 10)
    now = Elephant.for(@user).whiteness
    assert_operator now, :>, 0

    # 한 해가 지나도 그대로다.
    (1..370).step(37) do |days|
      travel_to @today + days do
        assert_in_delta now, Elephant.for(@user).whiteness, 1e-12, "#{days}일 뒤에 흰빛이 달라졌다"
      end
    end

    # 다른 도상의 것이 오가도 코끼리는 움직이지 않는다.
    @user.rests.create!(rested_on: @today, duration: "a_while")
    @user.clearings.create!(cleared_on: @today)
    assert_in_delta now, Elephant.for(@user).whiteness, 1e-12, "쉼이나 비움이 코끼리를 옮겼다"

    @user.rests.destroy_all
    @user.clearings.destroy_all
    assert_in_delta now, Elephant.for(@user).whiteness, 1e-12, "쉼이나 비움을 지우자 코끼리가 내려갔다"
  end

  # 앉을수록 오르기만 한다. 사이가 아무리 벌어져도 내려가는 구간이 없다.
  test "앉음을 거듭해도 내려가는 구간이 없다" do
    seen = []
    [ 60, 400, 20, 1000, 5 ].each_with_index do |minutes, index|
      sit(minutes: minutes, on: @today - (40 - index * 8))
      seen << Elephant.for(@user).whiteness
    end

    assert_equal seen.sort, seen, "흰빛이 내려간 구간이 있다"
  end

  # 코끼리는 걷지 않는다. 자리는 어떤 값에도 매이지 않는다 — 바위 하나다. 들어설 때
  # 가장자리에서 걸어오는 것은 자리의 변화가 아니라 문턱이다(§2, 2026-10-08).
  test "코끼리의 자리는 어떤 값에도 매이지 않는다 — 바위 하나" do
    css = Rails.root.join("app/assets/tailwind/application.css").read
    js = Rails.root.join("app/javascript/controllers/elephant_controller.js").read

    place = css[/\.elephant-place \{[^}]*\}/m].to_s
    assert_match(/left: var\(--rock-x\); top: var\(--rock-y\);/, place, "자리가 바위가 아니다")
    assert_no_match(/--x|--y|--angle|--flip/, place, "자리가 값을 받는다")
    # 왜 재지 않는지를 적은 주석은 걷어내고 코드만 본다.
    code = js.gsub(%r{^\s*//.*$}, "")
    assert_no_match(/getPointAtLength|setProperty\("--x"|setProperty\("--y"|whiteness/i, code,
      "스크립트가 흰빛으로 자리를 잰다")

    # 흰빛이 다른 두 사람의 코끼리가 같은 자리에 선다.
    sign_in_as @user
    get new_sitting_path
    bare = Nokogiri::HTML(response.body).at_css(".elephant-place")

    sit(minutes: 60 * 400, on: @today)
    get new_sitting_path
    seasoned = Nokogiri::HTML(response.body).at_css(".elephant-place")

    assert_equal bare["style"].to_s, seasoned["style"].to_s, "흰빛이 자리를 옮겼다"
    assert_nil bare["style"].presence, "자리가 화면마다 따로 적힌다"
  end

  # 흰빛을 깎는 코드가 없다 — 지우는 것은 사용자의 손이지 앱의 셈이 아니다.
  test "흰빛을 깎거나 되돌리는 코드가 없다" do
    sources = Rails.root.glob("app/**/*.{rb,erb,js}").map(&:read).join

    assert_no_match(/whiteness\s*[-*\/]=|whiteness\s*=\s*[\d.]+\s*[-*]/, sources, "흰빛을 깎는다")
    assert_no_match(/reset_whiteness|decay|penal/i, sources, "되돌리거나 벌하는 말이 있다")
  end

  private
    def sit(minutes:, on:)
      at = on.in_time_zone(@user.time_zone).change(hour: 7)
      @user.sittings.create!(mode: "sitting", sat_on: on, created_at: at, ended_at: at + minutes.minutes)
    end
end
