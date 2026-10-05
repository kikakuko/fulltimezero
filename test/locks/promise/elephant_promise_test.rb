# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 약속 — 코끼리(흔적)와 아홉 자리(안내)를 코드로 잇지 않는다. 이으면 앱이
# 「당신은 다섯째요」라고 말하게 된다. 그리고 쌓인 것은 무너지지 않는다 — 안 쉬면 창이
# 흘러가며 서서히 내려갈 뿐, 리셋은 없다(§3). 흰빛의 값과 결은 결 쪽이다 —
# test/locks/form/elephant_form_test.rb.
require "test_helper"

class ElephantPromiseTest < ActiveSupport::TestCase
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

  # 쉬지 않으면 서서히 내려갈 뿐이다. 0 으로 떨어지는 일은 없다 — 잊음이지 벌이 아니다.
  test "안 쉬면 서서히 내려갈 뿐, 리셋은 없다" do
    5.times { |i| @user.rests.create!(rested_on: @today - i, duration: "a_while") }
    now = Elephant.for(@user).whiteness

    later = (1..40).map { |days| Elephant.for(@user, today: @today + days).whiteness }

    assert_equal later.sort.reverse, later, "흰빛이 갑자기 오르거나 떨어진다"
    assert_operator later.first, :<=, now
    assert_operator later.each_cons(2).map { |a, b| a - b }.max, :<=, 1 / 28.0 + 1e-9, "하루에 하루치보다 더 내려간다"
    assert_equal 0.0, later.last
  end
end
