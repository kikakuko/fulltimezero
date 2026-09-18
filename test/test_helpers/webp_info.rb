# This app is a raft. — 이 앱도 뗏목이다.
#
# WebP 의 크기와 알파를 젬 없이 읽는다(§6 — 재려고 젬을 더하지 않는다).
# RIFF 덩어리를 훑어 VP8X(확장) · VP8(손실) · VP8L(무손실) 머리만 본다.
module WebpInfo
  def webp_info(path)
    data = Pathname(path).binread
    raise "WebP 가 아니다: #{path}" unless data[0, 4] == "RIFF" && data[8, 4] == "WEBP"

    at = 12
    info = { width: nil, height: nil, alpha: false }
    while at + 8 <= data.bytesize
      type = data[at, 4]
      length = data[at + 4, 4].unpack1("V")
      body = data[at + 8, length]

      case type
      when "VP8X"
        info[:alpha] = body.getbyte(0).anybits?(0x10)
        info[:width] = 1 + int24(body, 4)
        info[:height] = 1 + int24(body, 7)
      when "ALPH" then info[:alpha] = true
      when "VP8 "
        info[:width] ||= body[6, 2].unpack1("v") & 0x3fff
        info[:height] ||= body[8, 2].unpack1("v") & 0x3fff
      when "VP8L"
        bits = body[1, 4].unpack1("V")
        info[:width] ||= 1 + (bits & 0x3fff)
        info[:height] ||= 1 + ((bits >> 14) & 0x3fff)
        info[:alpha] ||= body.getbyte(4).anybits?(0x10)
      end
      at += 8 + length + (length.odd? ? 1 : 0)
    end
    info
  end

  private
    def int24(body, at) = body.getbyte(at) | (body.getbyte(at + 1) << 8) | (body.getbyte(at + 2) << 16)
end
