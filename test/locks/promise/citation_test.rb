# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 출전이 달린 문장은 모두 원문 대조를 거친 것이어야 한다 — 약속이다.
#
# 경에 없는 말에 경의 이름을 붙이는 것은 사용자가 배신당하는 자리다. 요약글에서
# 옮긴 문장, 기억에서 적은 문장, 누가 옮긴 것인지 모르는 문장에는 출전을 달지
# 않는다. 출전 없이 두는 것은 괜찮다 — 없는 것이 바른 모양이다.
#
# 「대조했다」는 표시는 Citation::CHECKED 에 한 줄로 있는 것이다. 그 줄에는
# 원문과 그것을 본 곳과 대조한 날이 함께 있다.
class CitationTest < ActionDispatch::IntegrationTest
  SOURCES = Rails.root.join("app/javascript/controllers/compound_controller.js")

  test "대조한 줄마다 원문과 본 곳과 대조한 날이 있다" do
    Citation::CHECKED.each do |key, checked|
      %i[ko en source_ko source_en original edition seen rendered_by checked_on].each do |field|
        assert checked[field].present?, "#{key} 의 #{field} 가 비었다"
      end

      assert_match(%r{\Ahttps://}, checked[:seen], "#{key} 의 본 곳이 주소가 아니다")
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, checked[:checked_on], "#{key} 의 대조한 날이 날짜가 아니다")
    end
  end

  # 원문은 저작권이 없지만 번역은 있다. 화면에 뜨는 것은 옮긴 문장이므로
  # 그것이 누구의 것인지가 표에 있어야 한다. 남의 번역본을 가져온 줄이 있으면
  # 역자와 발행처가 SOURCES.md 에도 남아 있어야 한다.
  test "옮긴 이가 적혀 있고, 남의 번역이면 출처 문서에 남아 있다" do
    ours = Rails.root.join("docs/SOURCES.md").read

    Citation::CHECKED.each do |key, checked|
      who = checked[:rendered_by].to_s
      assert who.present?, "#{key} 의 옮긴 이가 비었다"
      next if who.start_with?("이 앱")

      assert_includes ours, who, "#{key} 은 남의 번역인데 docs/SOURCES.md 에 역자와 발행처가 없다"
    end
  end

  # 화면에 나가는 문장이 대조한 그 문장인지. 문장을 고치면 여기가 울어 다시
  # 대조하게 한다 — 고친 문장에 옛 출전이 따라붙지 않도록.
  test "화면의 경구는 대조한 문장과 글자 그대로 같다" do
    Citation::CHECKED.each do |key, checked|
      %w[ko en].each do |locale|
        assert_equal checked[locale.to_sym], I18n.t("compound.detail.#{key}.verse", locale: locale),
          "#{key}(#{locale}) 의 경구가 대조한 문장과 다르다"
      end
    end
  end

  test "화면에 붙는 출전은 대조한 출전과 글자 그대로 같다" do
    js = SOURCES.read

    Citation::CHECKED.each do |key, checked|
      { "ko" => checked[:source_ko], "en" => checked[:source_en] }.each do |locale, source|
        block = js[/#{locale}: \{(.*?)\}/m, 1].to_s

        assert_includes block, %(#{key}: "#{source}"), "#{key}(#{locale}) 의 출전이 표와 다르다"
      end
    end
  end

  # 표에 없는 것에 출전이 붙으면 깨진다 — 경에 없는 말에 경의 이름을 붙이는 자리다.
  test "대조하지 않은 문장에는 출전이 붙지 않는다" do
    js = SOURCES.read

    %w[ko en].each do |locale|
      block = js[/#{locale}: \{(.*?)\}/m, 1].to_s
      named = block.scan(/(\w+): "/).flatten.map(&:to_sym)

      assert_equal Citation::CHECKED.keys.sort, named.sort,
        "#{locale} 의 출전 목록이 대조한 표와 다르다"
    end
  end

  # 경의 말로 서는 전각은 모두 대조를 거친 것이다. 우리 말로 서는 전각은 여기 없다.
  test "경으로 서는 전각은 모두 표에 있다" do
    scriptural = Compound::CARD_HALLS.select(&:scripture).map(&:key)

    assert_equal Citation::CHECKED.keys.sort, scriptural.sort
    Compound::CARD_HALLS.reject(&:scripture).each do |hall|
      assert_not Citation.checked?(hall.key), "#{hall.key} 는 먹으로 서는데 표에 있다"
    end
  end

  # 카피에 적힌 인용은 둘 중 하나여야 한다 — 원문으로 나가는 문(안내의 인용)을
  # 달고 있거나, 대조한 표의 출전을 쓰거나. 출전만 있고 둘 다 아니면 깨진다.
  test "카피의 인용마다 원문으로 나가는 문이 있거나 대조한 출전이 붙는다" do
    checked = Citation::CHECKED.values.flat_map { |one| [ one[:source_ko], one[:source_en] ] }

    I18n.available_locales.each do |locale|
      quotes(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale.to_s)).each do |item|
        shown = item["quote"].to_s[0, 30]
        cited = item["from"].presence || item["source"].presence

        assert cited.present?, "#{locale} 의 인용에 출전이 없다: #{shown}"
        next if item["link"].to_s.match?(%r{\Ahttps://})

        assert checked.any? { |source| source.start_with?(cited) },
          "#{locale} 의 인용에 원문으로 나가는 문도, 대조한 출전도 없다: #{shown} — #{cited}"
      end
    end
  end

  private
    def quotes(node)
      case node
      when Hash then node.key?("quote") ? [ node ] : node.values.flat_map { |value| quotes(value) }
      when Array then node.flat_map { |value| quotes(value) }
      else []
      end
    end
end
