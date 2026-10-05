# This app is a raft. — 이 앱도 뗏목이다.
#
# 그림의 무게 — propshaft 는 app/assets/images 를 통째로 싣는다. 화면이 늦게 뜨면 어떤
# 움직임도 살아나지 않는다(NEXT 4). 쓰지 않는 원본은 docs/sources 에 두고, 쓰는 그림은
# 화면에서 뜨는 크기의 두 배 안쪽에서 WebP 로 둔다.
require "test_helper"

class ImagesTest < ActiveSupport::TestCase
  IMAGES = Rails.root.join("app/assets/images")
  # 합계 바이트(2026-09-18). 늘리려면 왜 늘어야 하는지 먼저 따진다.
  MOST = 690_000

  test "그림의 합계가 정해 둔 무게를 넘지 않는다" do
    files = IMAGES.children.reject { |file| file.directory? || file.basename.to_s.start_with?(".") }
    total = files.sum(&:size)

    assert_operator total, :<=, MOST,
      "그림이 #{total} 바이트다(상한 #{MOST}). 줄이거나, 왜 늘어야 하는지 정하고 상한을 고친다.\n" +
      files.sort_by(&:size).reverse.first(5).map { |file| "  #{file.basename} #{file.size}" }.join("\n")
  end

  test "화면에 쓰는 그림은 WebP 이고, 쓰지 않는 원본은 파이프라인 밖에 있다" do
    assert_empty IMAGES.glob("*.png").map { |file| file.basename.to_s } - %w[apple-touch-icon.png icon-192.png icon-512.png icon-maskable-512.png],
      "아이콘 밖의 PNG 가 파이프라인 안에 있다 — WebP 로 바꾸고 원본은 docs/sources 로"
    %w[compound_src.png maitreya_src.png four_kings.png].each do |source|
      assert Rails.root.join("docs/sources", source).exist?, "#{source} 원본이 없다"
      assert_not IMAGES.join(source).exist?, "#{source} 이 파이프라인 안에 남아 있다"
    end
  end

  # 화면에서 뜨는 크기(폭 390 · 배율 2)의 두 배를 넘지 않는다.
  test "그림이 화면에서 뜨는 크기보다 크지 않다" do
    { "gates.webp" => 780, "mireukdang.webp" => 780, "elephant_field.webp" => 768,
      "compound.webp" => 768, "maitreya.webp" => 680, "four_king_left.webp" => 300,
      "four_king_right.webp" => 300 }.each do |name, most|
      assert_operator webp_info(IMAGES.join(name))[:width], :<=, most, "#{name} 이 화면에서 뜨는 크기보다 크다"
    end
  end
end
