# This app is a raft. — 이 앱도 뗏목이다.
#
# 선방의 세 걸음(docs/M-seonbang-room-design.md) — 방 → 탱화 앞 → 탱화 속. 앱이 하기로 한 것이라 깨지면
# 버그다. 걸음은 보는 자리만 바꾼다: 앉음은 한 줄이고, 걸음을 옮겨도 서버에 묻지 않으며, 어느 자리에서
# 앉았는지 적지 않는다.
require "test_helper"

class SeonbangStepsTest < ActionDispatch::IntegrationTest
  JS = Rails.root.join("app/javascript/controllers/seonbang_controller.js")

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "선방도 앉는 중도 방에서 시작하고, 걸음의 손잡이는 서버로 가지 않는 버튼이다" do
    get new_sitting_path
    assert_select ".seonbang[data-controller~=seonbang][data-step=room]", count: 1
    assert_select ".seonbang .seonbang__frame .elephant-field", count: 1, message: "족자 안에 산수가 없다"

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select ".night .seonbang[data-controller~=seonbang][data-step=room]", count: 1
    assert_select ".night .seonbang .seonbang__frame .elephant-field", count: 1

    # 걸음의 손잡이는 모두 type=button 이고 폼 밖에 있다 — 누른다고 요청이 나가지 않는다.
    css_select(".seonbang button").each do |button|
      assert_equal "button", button["type"], "걸음의 손잡이가 제출 버튼이다: #{button.text.strip}"
      assert_nil button.ancestors("form").first, "걸음의 손잡이가 폼 안에 있다"
    end
    assert_select ".seonbang a[href]", false, "걸음이 주소로 가는 링크다"
  end

  test "자리를 옮겨도 앉음은 하나다" do
    post sittings_path, params: { sitting: { length: "tea" } }
    sitting = @user.sittings.order(:id).last
    follow_redirect!

    # 걸음은 화면 쪽의 일이다. 같은 앉음 화면을 몇 번 다시 열어도(오가고 돌아와도) 앉음은 한 줄이다.
    3.times { get sitting_path(sitting) }
    assert_equal 1, @user.sittings.where(ended_at: nil).count, "걸음을 옮기다 앉음이 둘이 되었다"
    assert_select ".night .seonbang", count: 1

    js = JS.read
    assert_no_match(/\bfetch\(|XMLHttpRequest|Turbo\.visit|requestSubmit|\.submit\(|location\.(?:href\s*=|assign|replace)/, js,
      "걸음을 옮기는 손이 서버에 묻는다 — 앉음이 끊긴다")
    assert_match(/history\.pushState/, js, "뒤로 가기가 한 걸음 나옴이 아니다")
  end

  test "앉은 자리를 적지 않는다" do
    assert_empty Sitting.column_names.grep(/step|place|scroll|tangka|room|view/), "앉음에 자리 칸이 생겼다"

    post sittings_path, params: { sitting: { length: "tea", step: "within" } }
    assert_response :redirect
    assert_not_respond_to @user.sittings.order(:id).last, :step

    assert_no_match(/localStorage|sessionStorage|document\.cookie|indexedDB/, JS.read, "걸음을 어딘가에 적어 둔다")
  end
end
