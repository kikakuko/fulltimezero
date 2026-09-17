# This app is a raft. — 이 앱도 뗏목이다.
#
# importmap — 스크립트는 저장소 안에서만 온다. 바깥 주소(CDN)를 부르면 그것이 곧 제3자
# 요청이다(SPIRIT §6). 새 pin 은 더하기 전에 묻는다(CLAUDE.md).
#
# pin 이 가리키는 곳은 셋 가운데 하나여야 한다.
#   - app/javascript/ · vendor/javascript/ — 저장소 안의 파일.
#   - turbo-rails · stimulus-rails 젬의 파일 — Gemfile 에 잠긴 젬이 싣고 온다(dependency_test).
#     이 셋(turbo.min.js · stimulus.min.js · stimulus-loading.js)은 to: 가 파일 이름뿐이라
#     글자로는 자리를 알 수 없어, 실제로 찾아지는 파일의 자리로 가린다.
require "test_helper"

class ImportmapTest < ActiveSupport::TestCase
  IMPORTMAP = Rails.root.join("config/importmap.rb")
  # pin · pin_all_from 줄 수(2026-09-17 기준).
  PINS = 7
  INSIDE = %w[app/javascript/ vendor/javascript/].freeze
  GEMS = %w[turbo-rails stimulus-rails].freeze
  OUTSIDE = %r{\A(?:https?:)?//}i

  def source = IMPORTMAP.read.lines.reject { |line| line.strip.start_with?("#") }.join

  test "pin 의 수가 적어 둔 수와 같다 — 늘리기 전에 묻는다" do
    pins = source.lines.grep(/\A\s*pin(?:_all_from)?\s/)

    assert_equal PINS, pins.size,
      "importmap 의 pin 이 #{pins.size} 줄이다(적어 둔 수 #{PINS}). 새 pin 은 더하기 전에 묻고, 줄였으면 상수를 같이 고친다."
  end

  test "어느 pin 도 바깥 주소를 가리키지 않는다 — http · https · //" do
    source.scan(/\bpin(?:_all_from)?\s+["']([^"']+)["'](.*)$/).each do |name, rest|
      targets = [ name, *rest.scan(/(?:to|from):\s*["']([^"']+)["']/).flatten ]
      targets.each { |target| assert_no_match OUTSIDE, target, "pin #{name} 이 바깥을 가리킨다: #{target}" }
    end
    assert_no_match(%r{["'](?:https?:)?//}i, source, "importmap 에 바깥 주소가 적혀 있다")
  end

  test "모든 pin 이 저장소 안이나 잠긴 젬의 파일을 가리킨다" do
    map = Rails.application.importmap
    gem_dirs = GEMS.map { |name| Gem.loaded_specs.fetch(name).full_gem_path + "/" }

    map.packages.each_value do |package|
      assert_no_match OUTSIDE, package.path, "pin #{package.name} 이 바깥을 가리킨다: #{package.path}"

      asset = Rails.application.assets.load_path.find(package.path)
      assert asset, "pin #{package.name} 의 파일(#{package.path})이 저장소에서 찾아지지 않는다"

      file = asset.path.to_s
      inside = INSIDE.any? { |dir| file.start_with?(Rails.root.join(dir).to_s) }
      in_gem = gem_dirs.any? { |dir| file.start_with?(dir) }
      assert inside || in_gem, "pin #{package.name} 이 app/javascript · vendor/javascript · 잠긴 젬 밖을 가리킨다: #{file}"
    end

    map.directories.each_value do |directory|
      assert INSIDE.any? { |dir| directory.dir.to_s.start_with?(dir) }, "pin_all_from 이 저장소 밖이다: #{directory.dir}"
    end
  end
end
