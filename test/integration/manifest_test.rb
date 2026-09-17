# This app is a raft. — 이 앱도 뗏목이다.
#
# 홈 화면에 더한 앱 — 주소창 없이 전체 화면으로 뜨고, 바탕은 한지다. 매니페스트는 같은
# 자리(/manifest.json)에서 오므로 어느 주소로 열어도 제 것을 읽는다. 서비스 워커는 두지 않는다.
require "test_helper"

class ManifestTest < ActionDispatch::IntegrationTest
  test "매니페스트가 같은 자리에서 오고, 화면이 그것을 가리킨다" do
    get pwa_manifest_path
    assert_response :success
    manifest = JSON.parse(response.body)

    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
    assert_equal "/", manifest["scope"]
    assert_no_match(%r{\A(?:https?:)?//}, manifest["start_url"], "시작 주소가 바깥을 가리킨다")

    get new_session_path
    assert_select "head link[rel=manifest][href=?]", "/manifest.json"
    assert_select "head meta[name=apple-mobile-web-app-capable][content=yes]"
  end

  # 레일즈가 깔아 둔 빨간 원은 이 앱의 아이콘이 아니다 — 주사는 오늘 쓴 한 자에만 쓴다.
  # 아이콘 그림이 오기 전까지 매니페스트는 아이콘을 가리키지 않는다.
  test "매니페스트가 빨간 기본 아이콘을 가리키지 않는다" do
    get pwa_manifest_path
    icons = JSON.parse(response.body)["icons"].to_a

    icons.each do |icon|
      file = Rails.root.join("public", icon["src"].delete_prefix("/"))
      assert file.exist?, "아이콘 파일이 없다: #{icon['src']}"
      assert_no_match(/fill="red"/, Rails.root.join("public/icon.svg").read) if icon["src"].end_with?(".svg")
    end
    assert_empty icons.select { |icon| icon["src"] == "/icon.png" }, "레일즈 기본 빨간 원을 아이콘으로 쓴다"
  end
end
