# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 구름은 배경이다 — 도상 뒤에 있고, 어떤 때에도 도상을 덮지 않는다.
#
# §2 는 도상이 넷(달 · 코끼리 · 미륵 · 탑)이라고 못박았다. 배경이 도상 앞으로
# 나오면 다섯째 도상이 생기는 것과 같다. 그래서 이것은 결이 아니라 약속이다 —
# 짙기나 빠르기는 바뀔 수 있어도, 뒤에 선다는 것은 바뀌지 않는다.
class CloudTest < ActionDispatch::IntegrationTest
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  setup do
    heart_sutra
    nine_abidings
    sign_in_as users(:one)
  end

  test "구름의 겹은 바닥이다 — 도상보다 높은 자리에 서지 않는다" do
    cloud = CSS.read[/^\.cloud \{.*?\n\}/m].to_s
    layer = cloud[/z-index: (-?\d+)/, 1]

    assert_equal "0", layer, "구름이 제 겹을 올렸다"
    assert_no_match(/position: fixed/, cloud, "구름이 화면에 붙어 떠다닌다 — 그림 안에 있어야 한다")
  end

  test "마당에서 구름은 그림 뒤, 때의 빛과 전각 이름 앞에 선다" do
    get today_path
    scene = response.body[/<div class="compound__scene".*?<\/div>/m].to_s

    assert_operator scene.index("compound__map"), :<, scene.index("cloud--mist"), "구름이 그림보다 앞에 있다"
    assert_operator scene.index("cloud--mist"), :<, scene.index("daylight"), "때의 빛이 구름보다 뒤에 있다"
  end

  test "미륵당에서 구름은 미륵보다 뒤에 선다" do
    get days_path
    body = response.body

    assert_operator body.index("maitreya__yard"), :<, body.index("cloud--scroll"), "구름이 마당 그림보다 앞에 있다"
    assert_operator body.index("cloud--scroll"), :<, body.index("maitreya__earth"), "구름이 미륵을 덮는다"
  end

  test "산수화에서 구름은 코끼리와 정거장보다 뒤에 선다" do
    get new_sitting_path
    body = response.body

    assert_operator body.index("cloud--drift"), :<, body.index("elephant-field__map"), "구름이 길과 코끼리를 덮는다"
  end

  # 때가 달라져도 겹 차례는 그대로다 — 빛이 구름을 덮지, 구름이 빛을 덮지 않는다.
  test "어느 때에도 구름이 때의 빛 앞으로 나오지 않는다" do
    { "새벽" => 6, "낮" => 13, "저녁" => 18, "밤" => 23 }.each do |when_, hour|
      travel_to Time.zone.now.change(hour: hour) do
        get today_path
        scene = response.body[/<div class="compound__scene".*?<\/div>/m].to_s

        assert_match(/data-light="\w+"/, scene, "#{when_} 에 때의 빛이 없다")
        assert_operator scene.index("cloud--mist"), :<, scene.index("daylight"), "#{when_} 에 구름이 빛 앞으로 나왔다"
      end
    end
  end
end
