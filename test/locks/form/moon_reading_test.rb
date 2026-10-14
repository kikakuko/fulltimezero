# This app is a raft. — 이 앱도 뗏목이다.
#
# 화면을 읽어 주는 말 — 숫자 대신 그림을 말로 읽는다(2026-10-14, 헤이제임스). 「28일 중 20일」로
# 읽으면 숫자 금지를 어기고, 안 읽으면 비어 있다. 그래서 달은 「가늘다 · 반쯤 찼다 · 거의 찼다」
# 같은 묘사로, 코끼리는 「검은 · 옅어진 · 거의 흰」으로 읽는다. 단계의 이름이 아니라 그림의
# 묘사이므로 §3(판정 금지) · §5(수행 · 훈련 · 단계 · 레벨 금지)에 걸리지 않는다. 경계는 결이다.
require "test_helper"

class MoonReadingTest < ActionView::TestCase
  include MoonHelper
  include ElephantHelper

  test "달은 다섯 마디로 읽힌다 — 그믐 · 가늘다 · 반쯤 · 거의 · 보름" do
    readings = [ 0.0, 0.1, 0.34, 0.35, 0.5, 0.64, 0.65, 0.9, 1.0 ].map { |f| moon_reading(f) }

    assert_equal [ "moon.read.dark", "moon.read.thin", "moon.read.thin", "moon.read.half", "moon.read.half",
                   "moon.read.half", "moon.read.nearly", "moon.read.nearly", "moon.read.full" ].map { |k| I18n.t(k) }, readings
    svg = Nokogiri::HTML(moon_svg(0.5, size: 100)).at_css("svg")
    assert_equal "img", svg["role"]
    assert_equal I18n.t("moon.read.half"), svg["aria-label"]
    assert_equal I18n.t("moon.read.half"), svg.at_css("title").text
  end

  test "코끼리는 세 마디로 읽힌다 — 검은 · 옅어진 · 거의 흰" do
    assert_equal I18n.t("sittings.elephant.read.dark"), elephant_reading(0.0)
    assert_equal I18n.t("sittings.elephant.read.dark"), elephant_reading(0.32)
    assert_equal I18n.t("sittings.elephant.read.fading"), elephant_reading(0.33)
    assert_equal I18n.t("sittings.elephant.read.fading"), elephant_reading(0.79)
    assert_equal I18n.t("sittings.elephant.read.white"), elephant_reading(0.8)
    assert_equal I18n.t("sittings.elephant.read.white"), elephant_reading(1.0)
  end

  # 읽어 주는 말에는 숫자도, 단계 · 레벨 같은 낱말도 없다 — 그림의 묘사다.
  test "읽어 주는 말은 묘사다 — 숫자도 단계의 이름도 없다" do
    I18n.available_locales.each do |locale|
      words = %w[dark thin half nearly full].map { |k| I18n.t("moon.read.#{k}", locale: locale) } +
              %w[dark fading white].map { |k| I18n.t("sittings.elephant.read.#{k}", locale: locale) }

      words.each do |word|
        assert_no_match(/\d|%|단계|레벨|수행|훈련|level|stage|practice|training|percent/i, word, "#{locale}: #{word}")
      end
      assert_equal words.size, words.uniq.size, "#{locale}: 같은 말이 두 자리에 있다"
    end
  end
end
