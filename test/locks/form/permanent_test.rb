# This app is a raft. — 이 앱도 뗏목이다.
#
# 남겨 두는 요소(data-turbo-permanent)는 떠날 때 걷는다.
#
# Turbo 는 화면을 옮길 때 그 요소를 다시 그리지 않고 그대로 옮겨 붙이고, 떠나는 화면은
# 스냅숏으로 담아 두었다가 돌아올 때 먼저 깐다. 스크립트가 붙인 상태(클래스 · data-state)가
# 묻은 채 담기면, 돌아올 때 그 상태가 새 화면 대신 되살아난다 — 마당의 불이문에서 첫째 문으로
# 돌아오자 빛의 길이 다시 돈 것이 그것이다(2026-10-08). 그래서 그런 요소를 만지는 컨트롤러는
# 저마다 turbo:before-cache 에서 제가 붙인 것을 되돌린다.
require "test_helper"

class PermanentTest < ActiveSupport::TestCase
  VIEWS = Rails.root.join("app/views")
  CONTROLLERS = Rails.root.join("app/javascript/controllers")

  # 지금 남겨 두는 요소와, 그것을 만지는 컨트롤러. 새 요소가 생기거나 만지는 손이 늘면
  # 여기 적고 그 컨트롤러에 되돌리는 손을 붙인다.
  PERMANENT = { "gates" => %w[gates breath passage] }.freeze

  test "남겨 두는 요소는 #gates 하나다" do
    found = VIEWS.glob("**/*.erb").flat_map do |view|
      view.read.scan(/<\w+[^>]*\bdata-turbo-permanent\b[^>]*>/).map { |tag| tag[/\bid="([^"]+)"/, 1] || "(id 없음: #{view.relative_path_from(VIEWS)})" }
    end

    assert_equal PERMANENT.keys.sort, found.sort, "남겨 두는 요소가 늘거나 줄었다 — PERMANENT 와 되돌리는 손을 함께 손본다"
  end

  test "남겨 두는 요소를 만지는 컨트롤러마다 떠날 때 걷는다" do
    PERMANENT.each do |id, names|
      touching = CONTROLLERS.glob("*_controller.js").select do |file|
        js = file.read
        js.include?("getElementById(\"#{id}\")") || js.include?("querySelector(\"##{id}")
      end

      assert_equal names.sort, touching.map { |file| file.basename("_controller.js").to_s }.sort,
        "##{id} 를 만지는 컨트롤러가 PERMANENT 와 다르다"

      touching.each do |file|
        js = file.read
        mutates = js.match?(/classList\.add\(|dataset\.state = |dataset\.light = /)
        next unless mutates

        assert_match(/addEventListener\("turbo:before-cache"/, js,
          "#{file.basename} 이 ##{id} 에 상태를 붙이면서 떠날 때 걷지 않는다")
        assert_match(/removeEventListener\("turbo:before-cache"/, js,
          "#{file.basename} 이 떠날 때 걷는 손을 떼지 않는다 — 다음 화면까지 따라간다")
      end
    end
  end
end
