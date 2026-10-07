# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 절의 약속 넷.
#
#   절에 숫자가 붙지 않는다 — 몇 알인지도, 몇 분 남았는지도.
#   앱이 절의 속도를 정하지 않는다 — 사람이 절하고 사람이 누른다.
#   꿰인 알은 줄어들지 않는다 — 다 못 채우고 나가도 그 자리에 남는다(§3).
#   원은 백여덟에 한 번만 나타난다 — 매 절마다 뜨면 다섯째 도상이 된다(§2).
class BowingTest < ActionDispatch::IntegrationTest
  include Screens

  setup do
    heart_sutra
    @user = users(:one)
    sign_in_as @user
  end

  test "절하는 자리와 고르는 자리에 숫자가 없다" do
    I18n.available_locales.each do |locale|
      [ bows_path(locale: locale), bow_path("korean", locale: locale), bow_path("tibetan", locale: locale) ].each do |screen|
        get screen

        assert_response :success
        assert_no_match(/\d/, visible_text, "#{screen} 화면에 숫자가 보인다")
      end
    end
  end

  test "스크린리더에게도 세어 주지 않는다" do
    strung(50)
    get bow_path("korean")

    labels = Nokogiri::HTML(response.body).css("[aria-label], title").map(&:text).join(" ")

    assert_no_match(/\d/, labels, "접근성 텍스트에 숫자가 있다")
  end

  test "앱이 저절로 꿰지 않는다 — 알은 사람이 누를 때만 생긴다" do
    before = Bead.count

    get bow_path("korean")
    get bow_path("korean")

    assert_equal before, Bead.count, "화면을 여는 것만으로 알이 꿰였다"

    post beads_path(kind: "korean")
    assert_equal before + 1, Bead.count, "눌러도 알이 꿰이지 않는다"
  end

  test "스크립트가 알을 꿰지 않는다 — 칸만 넘긴다" do
    bow = Rails.root.join("app/javascript/controllers/bow_controller.js").read

    assert_no_match(/fetch\(|XMLHttpRequest|requestSubmit|\.submit\(/, bow, "스크립트가 스스로 알을 꿴다")
    assert_no_match(/setInterval/, bow, "스크립트가 절을 센다")
  end

  test "꿰인 알을 푸는 길이 없다" do
    ways = Rails.application.routes.routes.map { |route| "#{route.verb} #{route.path.spec}" }
      .select { |way| way.include?("beads") }

    assert_equal [ "POST /:locale/beads(.:format)" ], ways, "알을 푸는 길이 생겼다"

    # 계정을 지우면 함께 사라지는 것(has_many dependent)은 제 길이다 — 그것만 뺀다.
    writers = Rails.root.glob("app/{controllers,models,javascript}/**/*.{rb,js}")
      .select { |file| file.read.match?(/beads.*destroy|Bead.*destroy/) }
      .reject { |file| file.basename.to_s == "user.rb" }

    assert_empty writers.map { |file| file.relative_path_from(Rails.root).to_s },
      "알을 지우는 코드가 있다 — 계정을 지울 때 함께 사라지는 것 말고는 없어야 한다"
  end

  test "나갔다 들어와도 꿰인 알은 그 자리에 있다" do
    strung(30)
    delete session_path
    sign_in_as @user

    get bow_path("korean")
    assert_select "circle.rosary__bead", { count: 30 }, "꿰인 알이 줄었다"
  end

  test "원은 백여덟에 한 번만 나타난다" do
    strung(Bowing::FULL - 2)

    post beads_path(kind: "korean")
    follow_redirect!
    assert_select "circle.rosary__ring", false, "백여덟이 차기 전에 원이 나타났다"

    post beads_path(kind: "korean")
    follow_redirect!
    assert_select "circle.rosary__ring", { count: 1 }, "백여덟에 원이 닫히지 않았다"

    # 다음 알은 새 염주의 첫 알이다 — 원은 따라오지 않는다.
    post beads_path(kind: "korean")
    follow_redirect!
    assert_select "circle.rosary__ring", false, "원이 다음 염주까지 따라왔다"
    assert_select "circle.rosary__bead", { count: 1 }, "새 염주가 첫 알부터 시작하지 않는다"
  end

  private
    def strung(many, kind: "korean")
      many.times { @user.beads.create!(kind: kind, round: 1) }
    end
end
