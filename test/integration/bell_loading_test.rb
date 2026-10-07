# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 범종은 첫 화면에서 받지 않는다 — 성질이라 기능 쪽이다.
#
# 여운을 듣는 소리는 길고 무겁다. 그것이 첫 화면을 늦추면 들어오기도 전에 기다리게
# 된다. 범종각을 눌러 들어가 종을 칠 때에만 받는다 — 주소가 화면에 실려 있어도
# 받는 것은 누르는 그 순간이다(bell_controller 의 playFile).
#
# 무게의 값은 결이고(test/locks/form/sounds_test.rb), 「먼저 받지 않는다」는 기능이다.
class BellLoadingTest < ActionDispatch::IntegrationTest
  include Screens

  setup do
    heart_sutra
    nine_abidings
    sign_in_as users(:one)
  end

  test "범종의 주소는 범종각 밖 어느 화면에도 실리지 않는다" do
    each_page do |page, locale|
      assert_no_match(/bell-temple/, response.body, "#{page}(#{locale}) 가 범종을 미리 싣는다")
    end
  end

  test "어느 화면도 소리를 미리 받아 두지 않는다" do
    each_page do |page, locale|
      html = Nokogiri::HTML(response.body)

      assert_empty html.css("audio"), "#{page}(#{locale}) 에 소리 태그가 있다 — 누르기 전에 받는다"
      early = html.css("link[rel]").select do |link|
        link["rel"].to_s.split.intersect?(%w[preload prefetch]) &&
          (link["as"] == "audio" || link["href"].to_s.match?(/\.(ogg|mp3|wav|m4a|opus)/))
      end
      assert_empty early.map { |link| link["href"] }, "#{page}(#{locale}) 가 소리를 미리 받는다"
    end
  end

  test "범종각에서도 누르기 전에는 받지 않는다 — 주소만 있고 태그는 없다" do
    get bells_path

    assert_response :success
    assert_empty Nokogiri::HTML(response.body).css("audio"), "범종각이 들어서자마자 소리를 받는다"

    player = Rails.root.join("app/javascript/controllers/bell_controller.js").read
    assert_match(/playFile\(url, after\) \{\s*\n\s*const audio = new Audio\(url\)/, player,
      "소리를 누르는 순간이 아니라 미리 만든다")
  end
end
