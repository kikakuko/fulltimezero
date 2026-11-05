# This app is a raft. — 이 앱도 뗏목이다.
#
# 링크 그림(og)의 결 — app/assets/images/og/ 의 그림은 PNG 또는 JPEG, 저마다 1200×630, 120,000 바이트 이하.
# JPEG 를 받는 까닭(2026-11-05): og 는 문 밖의 결(B, 사진 같은 회화)이라 PNG 로는 120,000 에 들지 않는다
# (1200×630 에서 128색도 245,216). 링크 미리보기는 JPEG 를 가장 넓게 받는다. WebP 는 확인 전이라 받지 않는다.
# 화면의 그림 상한(images_test, 폴더 맨 위만 센다)과는 따로 잰다 — 이 그림은 크롤러만 받고
# 첫 화면의 무게에 들지 않는다. 로케일마다 한 장이 들어오면 여기서 저마다 잰다.
require "test_helper"

class OgImagesTest < ActiveSupport::TestCase
  OG = Rails.root.join("app/assets/images/og")
  MOST = 120_000
  SIZE = [ 1200, 630 ].freeze

  test "og 그림은 저마다 1200×630, 120,000 바이트 이하다" do
    images = OG.glob("*.{png,jpg}")
    assert_not_empty images, "og 그림이 한 장도 없다"

    images.each do |image|
      assert_operator image.size, :<=, MOST, "#{image.basename} 이 #{image.size} 바이트다(상한 #{MOST})"
      assert_equal SIZE, image_size(image), "#{image.basename} 이 1200×630 이 아니다"
    end
  end

  test "og 그림은 로케일의 이름으로만 선다" do
    names = OG.children.reject { |file| file.basename.to_s.start_with?(".") }.map { |file| file.basename.to_s }
    allowed = I18n.available_locales.flat_map { |locale| %W[#{locale}.png #{locale}.jpg] }

    assert_empty names - allowed, "로케일이 아닌 og 그림이 있다: #{(names - allowed).inspect}"
    I18n.available_locales.each do |locale|
      assert_operator names.count { |name| name.start_with?("#{locale}.") }, :<=, 1, "#{locale} 의 og 그림이 둘이다"
    end
  end

  private
    # 그림을 열지 않고 머리에서 너비와 높이를 읽는다 — PNG 는 IHDR, JPEG 는 SOF 표식.
    def image_size(path)
      data = path.binread
      return data[16, 8].unpack("NN") if data[0, 8] == "\x89PNG\r\n\x1A\n".b
      raise "PNG 도 JPEG 도 아니다: #{path}" unless data[0, 2] == "\xFF\xD8".b

      at = 2
      while at < data.bytesize
        marker = data.getbyte(at + 1)
        length = data[at + 2, 2].unpack1("n")
        return data[at + 5, 4].unpack("nn").reverse if (0xC0..0xCF).cover?(marker) && ![ 0xC4, 0xC8, 0xCC ].include?(marker)

        at += 2 + length
      end
      raise "JPEG 의 크기를 읽지 못했다: #{path}"
    end
end
