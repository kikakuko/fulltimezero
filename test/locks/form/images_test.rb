# This app is a raft. — 이 앱도 뗏목이다.
#
# 그림의 무게 — propshaft 는 app/assets/images 를 통째로 싣는다. 화면이 늦게 뜨면 어떤
# 움직임도 살아나지 않는다(NEXT 4). 쓰지 않는 원본은 docs/sources 에 두고, 쓰는 그림은
# 화면에서 뜨는 크기의 두 배 안쪽에서 둔다.
#
# 받는 쪽 기준(2026-11-05, docs/M-renewal-design.md): 그림은 AVIF 를 먼저 주고 WebP 를 받침으로
# 둔다. 한 화면은 둘 가운데 하나만 받으므로, 상한은 대부분의 사람이 받는 쪽(AVIF 가 있으면 AVIF,
# 없으면 WebP)으로 잰다. WebP 받침은 몰래 불어나지 않게 따로 잰다.
require "test_helper"

class ImagesTest < ActiveSupport::TestCase
  IMAGES = Rails.root.join("app/assets/images")
  # 받는 쪽 합계 바이트. 늘리려면 왜 늘어야 하는지 먼저 따진다.
  # 2026-09-18 에 690,000 으로 잡았고, 2026-10-07 에 960,000 으로 올렸다 —
  # 산수화의 구름 셋(안개띠 · 구름무리 · 가장자리 흐름, 합쳐 266KB)이 들어온다.
  # 구름은 화면을 가로질러 떠가므로 화면 폭보다 넓어야 하고(가로 1280), 색이
  # 그대로 있어야 한다 — 흰 구름이라 마스크로 바꾸면 몸통이 사라진다.
  #
  # 이 상한은 느린 망의 사용자를 지키던 값이다. 올린 만큼 되돌릴 자리를 적어 둔다:
  # 띄운 뒤 구름을 가로 1024 로 줄여 보고 눈에 차이가 없으면 그때 이 값도 함께 내린다
  # (NEXT.md 의 「그림 무게」).
  # 2026-11-06 에 1,110,000 으로 올렸다 — 첫 화면의 걸음 그림 여섯(원경 · 일주문 B · D3c · 천왕문 두 벽 · 불이문, AVIF q50
  # 합 388,262)이 옛 문 그림(gates · four_king_*, 140,299)을 갈음한다. 한 화면은 그 가운데 한 장만 처음 받으므로(걸음마다
  # 나눠 받는다) 화면의 무게는 따로 「화면마다 처음 받는 무게 ≤ 700,000」(landing_test)이 지킨다(docs/M-landing-design.md 8절).
  # 2026-11-10 에 1,400,000 으로 올렸다 — 경내 그림을 첫 화면과 같은 톤으로 새로 그린다(docs/M-art-renewal.md): 조감도 · 전각 안
  # 다섯(묘적광전 · 예경당 · 사경실 · 장경각 · 범종각) · 미륵당 바탕으로 약 +353,000. 한 화면은 그 가운데 한 장만 처음 받으므로
  # 화면의 무게는 landing_test · screen_weight_test(화면마다 처음 받는 무게)가 따로 지킨다.
  MOST = 1_400_000
  # WebP 받침의 합계. iOS 16 미만과 SVG 안의 <image> 가 받는다. 2026-11-05 에 792,078 이다.
  FALLBACK_MOST = 800_000

  def files = IMAGES.children.reject { |file| file.directory? || file.basename.to_s.start_with?(".") }

  # 받는 쪽 — 같은 이름의 AVIF 가 있으면 그것, 없으면 그 파일.
  def received
    files.reject { |file| file.extname == ".webp" && file.sub_ext(".avif").exist? }
  end

  test "받는 쪽 그림의 합계가 정해 둔 무게를 넘지 않는다" do
    total = received.sum(&:size)

    assert_operator total, :<=, MOST,
      "받는 그림이 #{total} 바이트다(상한 #{MOST}). 줄이거나, 왜 늘어야 하는지 정하고 상한을 고친다.\n" +
      received.sort_by(&:size).reverse.first(5).map { |file| "  #{file.basename} #{file.size}" }.join("\n")
  end

  test "WebP 받침의 합계가 따로 정해 둔 무게를 넘지 않는다" do
    total = IMAGES.glob("*.webp").sum(&:size)

    assert_operator total, :<=, FALLBACK_MOST, "WebP 받침이 #{total} 바이트다(상한 #{FALLBACK_MOST})"
  end

  test "화면에 쓰는 그림은 WebP(받침)이거나 AVIF 와 WebP 의 짝이고, 쓰지 않는 원본은 파이프라인 밖에 있다" do
    assert_empty IMAGES.glob("*.png").map { |file| file.basename.to_s } - %w[apple-touch-icon.png icon-192.png icon-512.png icon-maskable-512.png],
      "아이콘 밖의 PNG 가 파이프라인 안에 있다 — AVIF · WebP 로 바꾸고 원본은 docs/sources 로"
    IMAGES.glob("*.avif").each do |avif|
      assert avif.sub_ext(".webp").exist?, "#{avif.basename} 에 WebP 받침이 없다 — iOS 16 미만이 그림을 못 받는다"
    end
    IMAGES.glob("*.webp").each do |webp|
      assert webp.sub_ext(".avif").exist?, "#{webp.basename} 에 AVIF 가 없다 — 받는 쪽이 받침을 받는다"
    end
    %w[compound_src.png maitreya_src.png four_kings.png].each do |source|
      assert Rails.root.join("docs/sources", source).exist?, "#{source} 원본이 없다"
      assert_not IMAGES.join(source).exist?, "#{source} 이 파이프라인 안에 남아 있다"
    end
  end

  # 화면에서 뜨는 크기(폭 390 · 배율 2)의 두 배를 넘지 않는다.
  test "그림이 화면에서 뜨는 크기보다 크지 않다" do
    landing = %w[far gate_b gate_d wall_left wall_right burimun].to_h { |name| [ "landing_#{name}.webp", 768 ] }
    { "mireukdang.webp" => 780, "elephant_field.webp" => 768,
      "compound.webp" => 768, "maitreya.webp" => 680 }.merge(landing).each do |name, most|
      webp = IMAGES.join(name)
      assert webp.exist?, "#{name} 이 없다"
      avif = webp.sub_ext(".avif")
      # 첫 화면의 받침은 480 폭(q60)이다 — AVIF 를 못 받는 브라우저만 받으므로 받침만 줄여 받침 상한 안에 든다
      # (docs/M-landing-design.md 8절). 그래도 같은 그림이어야 하니 비율은 같다.
      if landing.key?(name)
        assert_operator avif_info(avif)[:width], :<=, most, "#{avif.basename} 이 화면에서 뜨는 크기보다 크다"
        assert_operator webp_info(webp)[:width], :<=, 480, "#{name} 받침이 480 폭보다 크다"
        a, w = avif_info(avif), webp_info(webp)
        assert_in_delta a[:width] / a[:height].to_f, w[:width] / w[:height].to_f, 0.005, "#{name} 받침의 비율이 그림과 다르다"
        next
      end
      assert_operator webp_info(webp)[:width], :<=, most, "#{name} 이 화면에서 뜨는 크기보다 크다"
      next unless avif.exist?

      assert_equal webp_info(webp).values_at(:width, :height), avif_info(avif).values_at(:width, :height),
        "#{avif.basename} 과 받침의 크기가 다르다 — 같은 그림의 두 형식이어야 한다"
    end
  end
end
