# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 범종각은 아무것도 쌓지 않는다 — 약속이다.
#
# 여덟 자리 가운데 유일하게 쌓지 않는 곳이다. 달도 탑도 코끼리도 미륵도
# 염주도 여기에는 없다. 「소리는 사라진다」가 이 전각이 말하는 전부인데,
# 친 횟수가 어딘가에 남으면 그 말이 거짓이 된다.
#
# 세지 않는 것은 결이 아니라 약속이다 — 세기 시작하면 사용자가 보던 것과
# 다른 앱이 된다.
class BellHallTest < ActionDispatch::IntegrationTest
  include Screens

  setup do
    heart_sutra
    @user = users(:one)
    sign_in_as @user
  end

  test "범종각으로 가는 길은 열어 보는 길 하나뿐이다" do
    ways = Rails.application.routes.routes
      .map { |route| "#{route.verb} #{route.path.spec}" }
      .select { |way| way.include?("bells") }

    assert_equal [ "GET /:locale/bells(.:format)" ], ways, "범종각에 쓰는 길이 생겼다"
  end

  test "종을 쳐도 쌓이는 것이 없다" do
    before = tally

    I18n.available_locales.each do |locale|
      3.times { get bells_path(locale: locale) }
    end

    assert_equal before, tally, "범종각을 지난 자리에 무언가 쌓였다"
  end

  test "범종각에는 숫자가 없다 — 횟수도, 남은 시간도" do
    I18n.available_locales.each do |locale|
      get bells_path(locale: locale)

      assert_response :success
      assert_no_match(/\d/, visible_text, "범종각(#{locale}) 화면에 숫자가 보인다")

      labels = Nokogiri::HTML(response.body).css("[aria-label], title").map(&:text).join(" ")
      assert_no_match(/\d/, labels, "범종각(#{locale}) 의 접근성 텍스트에 숫자가 있다")
    end
  end

  test "범종각을 담는 자리가 어디에도 없다 — 테이블도, 사용자의 것도, 내보내기도" do
    assert_not_includes ActiveRecord::Base.connection.tables, "bells", "범종각이 테이블을 가졌다"
    assert_empty User.reflect_on_all_associations.map(&:name).grep(/bell/), "종이 사용자에게 딸렸다"
    assert_empty Export::SECTIONS.keys.grep(/bell/), "내보내기에 종이 들어갔다"
  end

  # 소리를 내는 코드는 종성 컨트롤러 하나뿐이다(silence_test). 범종각도 그것을 쓴다.
  test "범종각은 제 손으로 소리를 내지 않는다 — 종성 컨트롤러를 지난다" do
    view = Rails.root.join("app/views/bells/show.html.erb").read

    assert_match(/data-controller="bell"/, view, "범종각이 종성 컨트롤러를 쓰지 않는다")
    assert_no_match(/new Audio|AudioContext|\.play\(\)/, view, "범종각이 제 손으로 소리를 낸다")
  end

  # 여운이 팔십팔 초다. 중간에 나가도 된다 — 다만 다른 화면까지 따라가면
  # 부르지 않은 소리가 되어 침묵 게이트에 가까워진다(§4). 그래서 약속이다.
  test "범종각을 떠나면 소리가 멎는다" do
    get bells_path
    assert_select ".bell-hall[data-bell-stop-on-leave-value=true]", { count: 1 },
      "범종각이 떠날 때 멎으라고 이르지 않는다"

    player = Rails.root.join("app/javascript/controllers/bell_controller.js").read
    assert_match(/disconnect\(\) \{[^}]*stopOnLeaveValue[^}]*\n\s*this\.hush\(\)/m, player,
      "떠날 때 멎는 자리가 없다")
    assert_match(/hush\(\) \{.*?this\.playing\.pause\(\)/m, player, "멎는 자리가 소리를 멈추지 않는다")
  end

  # 앉기의 시작종은 화면을 넘어가며 울려야 한다 — 「앉는다」를 누르는 손짓 안에서
  # 울리고 다음 화면으로 넘어간다. 거기서 멎으면 종이 울리지 않는다.
  test "앉기의 종은 떠난다고 멎지 않는다" do
    get new_sitting_path

    assert_select "[data-bell-stop-on-leave-value]", false,
      "앉기의 종이 화면을 떠날 때 멎는다 — 시작종이 울리지 못한다"
  end

  private
    # 모든 테이블의 행 수. 하나라도 늘면 쌓인 것이다.
    def tally
      ActiveRecord::Base.connection.tables.sort.to_h do |table|
        [ table, ActiveRecord::Base.connection.select_value("select count(*) from #{table}") ]
      end
    end
end
