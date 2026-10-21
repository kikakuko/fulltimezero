# This app is a raft. — 이 앱도 뗏목이다.
#
# 링크 그림(og)의 결 — app/assets/images/og/ 의 그림은 저마다 1200×630, 120,000 바이트 이하.
# 화면의 그림 상한(images_test, 폴더 맨 위만 센다)과는 따로 잰다 — 이 그림은 크롤러만 받고
# 첫 화면의 무게에 들지 않는다. 로케일마다 한 장이 들어오면 여기서 저마다 잰다.
require "test_helper"

class OgImagesTest < ActiveSupport::TestCase
  OG = Rails.root.join("app/assets/images/og")
  MOST = 120_000
  SIZE = [ 1200, 630 ].freeze

  test "og 그림은 저마다 1200×630, 120,000 바이트 이하다" do
    images = OG.glob("*.png")
    assert_not_empty images, "og 그림이 한 장도 없다"

    images.each do |image|
      assert_operator image.size, :<=, MOST, "#{image.basename} 이 #{image.size} 바이트다(상한 #{MOST})"
      assert_equal SIZE, png_size(image), "#{image.basename} 이 1200×630 이 아니다"
    end
  end

  test "og 그림은 로케일의 이름으로만 선다" do
    names = OG.children.reject { |file| file.basename.to_s.start_with?(".") }.map { |file| file.basename.to_s }
    allowed = I18n.available_locales.map { |locale| "#{locale}.png" }

    assert_empty names - allowed, "로케일이 아닌 og 그림이 있다: #{(names - allowed).inspect}"
  end

  private
    # PNG 머리(IHDR)의 너비와 높이 — 그림을 열지 않고 읽는다.
    def png_size(path)
      data = path.binread(24)
      raise "PNG 가 아니다: #{path}" unless data[0, 8] == "\x89PNG\r\n\x1A\n".b

      data[16, 8].unpack("NN")
    end
end
