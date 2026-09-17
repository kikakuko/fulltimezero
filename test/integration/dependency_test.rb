# This app is a raft. — 이 앱도 뗏목이다.
#
# 바깥에서 들이는 것 — 새 젬이나 바깥 서비스는 더하기 전에 먼저 묻는다(CLAUDE.md, SPIRIT §6).
# 항목 수가 지금보다 늘면 깨진다. 물어서 허락을 받았으면 그때 이 상수를 올린다.
# 줄일 때도 상수를 같이 고친다 — 수가 맞지 않으면 역시 깨진다.
require "test_helper"

class DependencyTest < ActiveSupport::TestCase
  # Gemfile 의 gem 줄 수(2026-09-17 기준). image_processing 을 빼서 스물여섯에서 스물다섯 —
  # 어디에서도 쓰지 않는데 메이저 올림을 받으려면 ruby-vips 를 더해야 했다.
  GEMS = 25
  # package.json 의 dependencies · devDependencies 항목 수. 지금은 파일이 없다 — importmap 으로 간다.
  PACKAGES = 0

  test "Gemfile 의 젬 수가 적어 둔 수와 같다 — 늘리기 전에 묻는다" do
    gems = Rails.root.join("Gemfile").read.lines.grep(/\A\s*gem\s+["']/)

    assert_equal GEMS, gems.size,
      "Gemfile 의 젬이 #{gems.size} 줄이다(적어 둔 수 #{GEMS}). 새 젬은 더하기 전에 묻고, 줄였으면 상수를 같이 고친다."
  end

  test "package.json 의 항목 수가 적어 둔 수와 같다 — 늘리기 전에 묻는다" do
    file = Rails.root.join("package.json")
    packages = file.exist? ? JSON.parse(file.read).values_at("dependencies", "devDependencies").compact.sum(&:size) : 0

    assert_equal PACKAGES, packages,
      "package.json 의 항목이 #{packages} 개다(적어 둔 수 #{PACKAGES}). 새 꾸러미는 더하기 전에 묻고, 줄였으면 상수를 같이 고친다."
  end
end
