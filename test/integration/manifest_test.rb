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

  ICONS = %w[apple-touch-icon.png icon-192.png icon-512.png icon-maskable-512.png icon.svg].freeze
  CINNABAR = [ 0xd9, 0x43, 0x2f ].freeze

  # 아이콘은 한지 위의 먹빛 코끼리다. 주사는 오늘 쓴 한 자에만 쓰므로 앱의 얼굴에 닿지 않는다.
  # 레일즈가 깔아 둔 빨간 원(public/icon.*)은 걷었다.
  test "아이콘 다섯이 매니페스트와 화면에 이어지고, 어느 것에도 주사가 닿지 않는다" do
    get pwa_manifest_path
    icons = JSON.parse(response.body)["icons"]

    assert_equal 4, icons.size
    assert_equal 1, icons.count { |icon| icon["purpose"] == "maskable" }
    icons.each { |icon| assert_no_match(%r{\A(?:https?:)?//}, icon["src"], "아이콘이 바깥을 가리킨다") }
    %w[icon-192 icon-512 icon-maskable-512 icon].each do |name|
      assert icons.any? { |icon| icon["src"].match?(%r{\A/assets/#{name}-\h+\.(?:png|svg)\z}) }, "매니페스트가 #{name} 을 가리키지 않는다"
    end

    get new_session_path
    assert_select "head link[rel=icon][href^='/assets/icon-'][type='image/svg+xml']", count: 1
    assert_select "head link[rel=apple-touch-icon][href^='/assets/apple-touch-icon-'][sizes='180x180']", count: 1
    assert_not Rails.root.join("public/icon.png").exist?, "빨간 원이 남아 있다"
    assert_not Rails.root.join("public/icon.svg").exist?, "빨간 원이 남아 있다"

    ICONS.each do |name|
      file = Rails.root.join("app/assets/images", name)
      assert file.exist?, "#{name} 이 없다"

      if name.end_with?(".svg")
        svg = file.read
        assert_no_match(/#{CINNABAR.map { |c| format('%02x', c) }.join}|\bred\b|rgb\(/i, svg, "#{name} 에 주사가 닿았다")
        assert_no_match(/<script|href=|https?:\/\/(?!www\.w3\.org)/i, svg, "#{name} 이 바깥을 부르거나 스크립트를 품는다")
      else
        reds = png_pixels(file).count { |r, g, b| red?(r, g, b) }
        assert_equal 0, reds, "#{name} 에 붉은 점이 #{reds} 개 있다"
      end
    end
  end

  private
    def red?(r, g, b)
      near_cinnabar = [ r, g, b ].zip(CINNABAR).sum { |a, c| (a - c)**2 } < 60**2
      near_cinnabar || (r > 150 && r - g > 60 && r - b > 60)
    end

    # PNG 를 표준 zlib 만으로 푼다(젬을 더하지 않는다). 8비트 RGB · RGBA, 인터레이스 없음.
    def png_pixels(file)
      data = file.binread
      assert_equal "\x89PNG\r\n\x1A\n".b, data[0, 8]
      width = height = depth = color = nil
      idat = +"".b
      at = 8
      while at < data.bytesize
        length = data[at, 4].unpack1("N")
        type = data[at + 4, 4]
        body = data[at + 8, length]
        case type
        when "IHDR" then width, height, depth, color, _, _, interlace = body.unpack("NNCCCCC")
        when "IDAT" then idat << body
        end
        at += 12 + length
      end
      assert_equal 8, depth
      assert_includes [ 2, 6 ], color
      assert_equal 0, interlace

      channels = color == 6 ? 4 : 3
      raw = Zlib::Inflate.inflate(idat).bytes
      stride = width * channels
      previous = Array.new(stride, 0)
      pixels = []
      height.times do |row|
        start = row * (stride + 1)
        filter = raw[start]
        line = raw[start + 1, stride]
        line.each_index do |i|
          left = i >= channels ? line[i - channels] : 0
          up = previous[i]
          upper_left = i >= channels ? previous[i - channels] : 0
          line[i] = (line[i] + case filter
                     when 0 then 0
                     when 1 then left
                     when 2 then up
                     when 3 then (left + up) / 2
                     when 4 then paeth(left, up, upper_left)
                     end) & 0xff
        end
        line.each_slice(channels) { |pixel| pixels << pixel.first(3) }
        previous = line
      end
      pixels
    end

    def paeth(a, b, c)
      p = a + b - c
      pa, pb, pc = (p - a).abs, (p - b).abs, (p - c).abs
      pa <= pb && pa <= pc ? a : (pb <= pc ? b : c)
    end
end
