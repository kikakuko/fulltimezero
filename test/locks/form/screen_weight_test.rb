# This app is a raft. — 이 앱도 뗏목이다.
#
# 화면마다 처음 받는 무게 — 마당 · 선방 · 미륵당은 지금 무게를 상한으로 잠근다(늘지 않게, 2026-11-10). 목표는 첫 화면과 같은
# 700,000(landing_test)이고, 줄이는 일은 docs/NEXT.md 20 에 있다. 결 자물쇠다 — 줄이면 상한도 함께 내린다.
#
# 셈은 landing_test 와 같다: 화면의 HTML + 스타일 · 스크립트 + 이 화면에 쓰이는 글꼴 + 처음에 받는 그림(받는 쪽 — <picture> 의 AVIF,
# 지연 아닌 <img>, SVG 안의 <image>, 그 화면의 CSS 배경). 압축 전의 파일 크기. 개발 서버의 실측(2026-11-10, 390 폭,
# encodedBodySize 합)은 마당 683,244 · 선방 1,133,360 · 미륵당 750,929 였다 — HTML 이 시험의 자료로 달라 조금 다르다.
require "test_helper"

class ScreenWeightTest < ActionDispatch::IntegrationTest
  IMAGES = Rails.root.join("app/assets/images")
  FONTS = Rails.root.join("app/assets/fonts")
  # 화면 · 그 화면의 CSS 배경 그림(받는 쪽) · 상한(셈을 천 단위로 올린 값). 2026-11-10 에 선방 · 마당의 구름 둘을 가로 1280 → 1024
  # 로 다시 눌러 줄인 값으로 다시 잠갔다 — 선방 1,079,564 → 1,034,828 · 마당 743,204 → 735,412 · 미륵당 706,254(그대로). 마당은
  # 새 세션의 첫 화면이라 매일의 문(일주문 B · D3c)이 함께 든다 — 가장 무거운 때로 잠근다.
  SCREENS = {
    today_path: { backgrounds: %w[cloud-mist.avif], most: 736_000 },
    new_sitting_path: { backgrounds: %w[elephant_field.avif cloud-drift.webp], most: 1_035_000 },
    days_path: { backgrounds: %w[cloud-scroll.avif], most: 707_000 }
  }.freeze

  setup { sign_in_as users(:one) }

  test "마당 · 선방 · 미륵당은 처음 받는 무게가 지금보다 늘지 않는다" do
    SCREENS.each do |path, screen|
      get send(path)
      total = response.body.bytesize + common_bytes + images_bytes(response.body, screen[:backgrounds])
      puts "#{path}: #{total}" if ENV["SHOW_WEIGHT"]
      assert_operator total, :<=, screen[:most],
        "#{path} 가 처음에 #{total} 바이트를 받는다(상한 #{screen[:most]}) — 늘었다. 줄이거나 왜 늘어야 하는지 정하고 상한을 고친다"
    end
  end

  private
    def common_bytes
      # 스타일은 원본에서 주석과 빈칸을 걷은 크기로 잰다 — 빌드 결과(builds/tailwind.css)는 손질하는 곳마다 조금씩 달라(로컬과
      # CI 가 14,573 바이트 달랐다, 2026-11-10) 상한이 흔들린다.
      css = Rails.root.join("app/assets/tailwind/application.css").read.gsub(%r{/\*.*?\*/}m, "").gsub(/\s+/, " ").bytesize
      js = Rails.root.glob("app/javascript/**/*.js").sum(&:size) + Rails.root.glob("vendor/javascript/*.js").sum(&:size) +
           %w[turbo-rails stimulus-rails].sum do |gem|
             Gem.loaded_specs[gem] ? Pathname(Gem.loaded_specs[gem].full_gem_path).glob("app/assets/javascripts/*.min.js").sum(&:size) : 0
           end
      # 이 셋 화면은 한글(동해독도)과 전각의 한자(霞鶩文楷)를 쓴다.
      css + js + %w[EastSeaDokdo.woff2 WenKaiTC.woff2].sum { |name| FONTS.join(name).size }
    end

    # 처음에 받는 그림 — <picture> 는 AVIF 를, 지연(lazy)인 그림은 빼고, SVG 의 <image> 는 그 파일을. 같은 그림은 한 번.
    def images_bytes(html, backgrounds)
      page = Nokogiri::HTML(html)
      names = page.css("img:not([loading=lazy])").map do |img|
        avif = img.parent&.name == "picture" && img.parent.at_css("source[type='image/avif']")
        avif ? avif["srcset"] : img["src"]
      end
      names += page.css("image").map { |image| image["href"] || image["xlink:href"] }
      # CSS 배경과 SVG 의 <image> 가 같은 그림이면 한 번만 받는다(선방의 cloud-drift).
      (names.compact.map { |url| File.basename(url.split("?").first).sub(/-\h{8,}(?=\.)/, "") } + backgrounds).uniq
           .sum { |name| IMAGES.join(name).exist? ? IMAGES.join(name).size : 0 }
    end
end
