# This app is a raft. — 이 앱도 뗏목이다.
#
# SPIRIT.md 를 코드가 아니라 화면에서 검증한다.
require "test_helper"

class SpiritTest < ActionDispatch::IntegrationTest
  OPEN_PAGES = %i[gate_path new_user_path new_session_path new_password_path guide_path privacy_path].freeze
  SIGNED_IN_PAGES = %i[today_path new_rest_path moon_path settings_path new_sitting_path].freeze

  # 화면에 숫자·퍼센트·분·"n일째"가 없어야 한다.
  test "어느 화면에도 숫자나 지표가 보이지 않는다" do
    each_page do |page, locale|
      text = visible_text

      assert_no_match(/\d/, text, "#{page}(#{locale}) 화면에 숫자가 보인다")
      assert_no_match(/%/, text, "#{page}(#{locale}) 화면에 퍼센트가 보인다")
      assert_no_match(/일째|days?\b.*streak|streak/i, text, "#{page}(#{locale}) 화면에 연속기록이 보인다")
      assert_no_match(/\d\s*(분|minutes?|mins?)\b/i, text, "#{page}(#{locale}) 화면에 분이 보인다")
    end
  end

  # 앉는 중과 무위는 기록이 있어야 열리므로 따로 연다.
  test "앉는 중에도 무위에도 숫자가 없고, 바깥을 부르지 않는다" do
    user = users(:one)
    sign_in_as user

    %i[ko en].each do |locale|
      post sittings_path(locale: locale), params: { sitting: { length: "incense", bell: "1" } }
      follow_redirect!
      assert_quiet_screen "앉는 중", locale

      post nothing_path(locale: locale), params: { bell: "1" }
      follow_redirect!
      assert_quiet_screen "무위", locale
    end
  end

  # 남은 시간을 스크린리더에게만 숫자로 알려주지 않는다.
  # 보이는 사람도 모르는 것을 들리는 사람에게만 알려주는 것은 형평이 아니다.
  test "앉는 중 화면은 스크린리더에게도 남은 시간을 말하지 않는다" do
    sign_in_as users(:one)
    post sittings_path, params: { sitting: { length: "long" } }
    follow_redirect!

    labels = Nokogiri::HTML(response.body).css("[aria-label], title").map(&:text).join(" ")

    assert_no_match(/\d/, labels, "접근성 텍스트에 숫자가 있다")
    assert_no_match(/분|minutes?|remaining|남은/i, labels)
  end

  # 카피는 전량 로케일 파일에 있다. 그 안에 숫자가 하나도 없어야
  # 화면에 숫자가 없다는 말이 우연이 아니게 된다.
  test "카피 어디에도 숫자가 없다" do
    %w[ko en].each do |locale|
      copy = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)

      flatten_copy(copy).each do |line|
        assert_no_match(/\d/, line, "#{locale} 카피에 숫자가 있다: #{line.inspect}")
      end
    end
  end

  test "어느 화면에도 이모지와 느낌표가 없다" do
    each_page do |page, locale|
      text = visible_text
      assert_no_match(/!/, text, "#{page}(#{locale}) 화면에 느낌표가 있다")
      assert_no_match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/, text, "#{page}(#{locale}) 화면에 이모지가 있다")
    end
  end

  test "어느 화면도 제3자에게 요청을 보내지 않는다" do
    each_page do |page, locale|
      hosts = response.body.scan(%r{https?://([^/"'\s>]+)}).flatten.uniq
      assert_empty hosts, "#{page}(#{locale}) 화면이 바깥을 부른다: #{hosts.inspect}"
    end
  end

  test "쉼을 기록해도 알림은 한 통도 나가지 않는다" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      post rests_path(locale: :ko), params: { rest: { duration: "a_while" } }
      get today_path(locale: :ko)
      get moon_path(locale: :ko)
    end
  end

  test "달의 자취는 날짜도 합계도 보이지 않고 점만 남긴다" do
    user = users(:one)
    3.times { |i| user.rests.create!(rested_on: user.today - i, duration: "a_moment") }
    sign_in_as user

    get moon_path(locale: :ko)
    assert_select ".trail span", count: MoonPhase::WINDOW_DAYS
    assert_select ".trail span.on", count: 3
    assert_no_match(/\d/, visible_text)
  end

  # 「쉼의 안내」에 인용문이 들어온다면 그 출처는 CC0 원문뿐이어야 한다.
  test "쉼의 안내에는 출처 없는 인용문이 없다" do
    sources = File.read(Rails.root.join("docs/SOURCES.md"))
    assert_match(/CC0/, sources, "출처 문서에 라이선스 원칙이 없다")

    copy = %i[ko en].flat_map { |l| flatten_copy(I18n.t("guide", locale: l)) }.join(" ")
    quotations = copy.scan(/[“「『]([^”」』]+)[”」』]/).flatten

    quotations.each do |quotation|
      assert_includes sources, quotation.strip,
        "인용문 #{quotation.inspect} 의 출처가 docs/SOURCES.md 에 없다"
    end
  end

  private
    def assert_quiet_screen(name, locale)
      assert_response :success, "#{name}(#{locale}) 이 열리지 않는다"

      text = visible_text
      assert_no_match(/\d/, text, "#{name}(#{locale}) 화면에 숫자가 보인다")
      assert_no_match(/\d\s*(분|minutes?|mins?)\b/i, text, "#{name}(#{locale}) 화면에 분이 보인다")

      hosts = response.body.scan(%r{https?://([^/"'\s>]+)}).flatten.uniq
      assert_empty hosts, "#{name}(#{locale}) 화면이 바깥을 부른다: #{hosts.inspect}"
    end

    def flatten_copy(node)
      case node
      when Hash then node.values.flat_map { |v| flatten_copy(v) }
      when Array then node.flat_map { |v| flatten_copy(v) }
      else [ node.to_s ]
      end
    end

    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end

    def each_page
      %i[ko en].each do |locale|
        OPEN_PAGES.each do |page|
          get public_send(page, locale: locale)
          assert_response :success, "#{page}(#{locale}) 가 열리지 않는다"
          yield page, locale
        end

        sign_in_as users(:one)
        SIGNED_IN_PAGES.each do |page|
          get public_send(page, locale: locale)
          assert_response :success, "#{page}(#{locale}) 가 열리지 않는다"
          yield page, locale
        end
        sign_out
      end
    end
end
