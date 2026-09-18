# This app is a raft. — 이 앱도 뗏목이다.
#
# PNG 의 픽셀을 젬 없이 읽는다(§6 — 재려고 젬을 더하지 않는다). 표준 zlib 으로 풀고
# 필터만 되돌린다. 8비트 RGB · RGBA, 인터레이스 없는 파일에만 쓴다.
module PngPixels
  Read = Struct.new(:width, :height, :channels, :pixels) do
    # 한 점 — [r, g, b, (a)]
    def at(x, y) = pixels[y * width + x]
  end

  def png_read(path)
    data = Pathname(path).binread
    raise "PNG 이 아니다: #{path}" unless data[0, 8] == "\x89PNG\r\n\x1A\n".b

    width = height = depth = color = interlace = nil
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
    raise "8비트 RGB · RGBA, 인터레이스 없는 PNG 만 읽는다" unless depth == 8 && [ 2, 6 ].include?(color) && interlace.zero?

    channels = color == 6 ? 4 : 3
    Read.new(width, height, channels, unfilter(Zlib::Inflate.inflate(idat).bytes, width, height, channels))
  end

  private
    def unfilter(raw, width, height, channels)
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
        line.each_slice(channels) { |pixel| pixels << pixel }
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
