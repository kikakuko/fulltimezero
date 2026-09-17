# This app is a raft. — 이 앱도 뗏목이다.
#
# 부품 다섯 — 카드 · 먹 알약 버튼 · 조용한 버튼 · 인용 · 먹틀. 여섯 화면이 모두 옮긴 뒤
# 옛 버튼(알약 테두리 버튼, 글자뿐인 버튼, 맨 버튼)을 걷었다. 되살아나면 부품이 둘로 갈린다.
require "test_helper"

class ComponentTest < ActionDispatch::IntegrationTest
  # 옛 이름. 이 파일 밖의 코드에 나타나면 깨진다.
  OLD = %w[action quiet plain].freeze

  test "옛 버튼은 코드 어디에도 없다 — 뷰 · 스타일 · 스크립트 · 헬퍼 · 로케일" do
    files = Rails.root.glob("{app,config}/**/*.{erb,css,js,rb,yml}").reject { |file| file.to_s.include?("/builds/") }

    files.each do |file|
      source = file.read
      name = file.relative_path_from(Rails.root)

      OLD.each do |old|
        assert_no_match(/class(?:=|: )"(?:[^"]*\s)?#{old}(?:\s[^"]*)?"/, source, "#{name} 에 옛 버튼 #{old} 이 붙었다")
        assert_no_match(/classList\.\w+\("#{old}"/, source, "#{name} 의 스크립트가 옛 버튼 #{old} 을 붙인다")
      end
      next unless file.extname == ".css"

      assert_no_match(/\.action\b/, source, "#{name} 에 옛 .action 규칙이 남아 있다")
      assert_no_match(/button\.(?:quiet|plain)\b/, source, "#{name} 에 옛 글자 버튼 규칙이 남아 있다")
      assert_no_match(/(?<![\w-])\.(?:quiet|plain)\s*\{/, source, "#{name} 에 옛 버튼 규칙이 남아 있다")
    end
  end
end
