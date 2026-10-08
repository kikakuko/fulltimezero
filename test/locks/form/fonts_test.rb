# This app is a raft. — 이 앱도 뗏목이다.
#
# 글꼴의 무게 — 그림(images_test) · 소리(sounds_test)와 따로 잰다. 글꼴은 저장소 안의
# 파일이고(type_test), 화면의 글자가 부르는 만큼만 실린다 — 한국어 마당은 한글과 한자 둘,
# 영어 마당은 알파벳과 한자 둘. 합계는 어느 화면이든 받을 수 있는 가장 무거운 경우다.
# 넘기지 않는다 — 넘으면 상한을 올리지 말고 글자를 더 추린다. 세 무게의 합은 docs/STATUS.md 에.
require "test_helper"

class FontsTest < ActiveSupport::TestCase
  FONTS = Rails.root.join("app/assets/fonts")
  # 합계 바이트. 2026-10-08 에 400,000 으로 잡았다 — 그때 셋이 354,160 이었다(동해독도 232,220 · Caveat Brush 67,088 · WenKai TC 54,852).
  MOST = 400_000

  test "글꼴의 합계가 정해 둔 무게를 넘지 않는다" do
    files = FONTS.glob("*.woff2")
    total = files.sum(&:size)

    assert_operator total, :<=, MOST,
      "글꼴이 #{total} 바이트다(상한 #{MOST}). 상한을 올리지 말고 글자를 더 추린다.\n" +
      files.sort_by(&:size).reverse.map { |file| "  #{file.basename} #{file.size}" }.join("\n")
  end

  # 글꼴마다 라이선스 전문이 곁에 있다 — 받은 글꼴은 그 조건과 함께 다닌다.
  test "글꼴마다 라이선스 전문이 곁에 있다" do
    FONTS.glob("*.woff2").each do |file|
      stem = file.basename(".woff2").to_s.downcase
      assert FONTS.join("#{stem}-OFL.txt").exist?, "#{file.basename} 의 OFL 전문(#{stem}-OFL.txt)이 app/assets/fonts 에 없다"
    end
  end
end
