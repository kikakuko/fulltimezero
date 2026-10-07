# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리의 결 — 얼마나 느리게 희어지는가. 「쌓이기만 한다」는 성질이라
# 기능 쪽에 있다(test/models/elephant_test.rb).
require "test_helper"

class ElephantWhiteTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.sittings.destroy_all
    @today = @user.today
  end

  # 백오십 시간을 자로 삼는다. 느리게 오래 가는 값이다 — 하루 한 시간씩 앉으면
  # 반년에 예순세 푼쯤이고, 그 뒤로는 더 느려진다.
  test "한 시간을 세는 자는 백오십이다" do
    assert_equal 150.0, Elephant::SOAK_HOURS
    assert_match(/1 - Math\.exp\(-hours\(user, ending: ending\) \/ SOAK_HOURS\)/,
      Rails.root.join("app/models/elephant.rb").read, "흰빛의 셈이 바뀌었다")
  end

  # 한 번의 앉음은 눈에 띄지 않을 만큼만 옮긴다. 희어짐은 앉는 동안이 아니라
  # 앉음과 앉음 사이에서 보인다.
  test "한 번 앉아 옮겨 가는 폭은 백분의 일을 넘지 않는다" do
    at = @today.in_time_zone(@user.time_zone).change(hour: 7)
    before = Elephant.for(@user).whiteness
    @user.sittings.create!(mode: "sitting", sat_on: @today, created_at: at, ended_at: at + 20.minutes)

    assert_operator Elephant.for(@user).whiteness - before, :<, 0.01
  end

  # 길의 굽이는 아홉이다 — 그림의 기하일 뿐 이름도 글도 붙지 않는다(§2).
  test "길의 굽이는 아홉이고 이름이 없다" do
    assert_equal 9, Elephant::ANCHORS.size
    assert_not Elephant::Reading.new(whiteness: 0.5, yesterday: 0.5).respond_to?(:station),
      "굽이를 자리로 세는 길이 되살아났다"
  end
end
