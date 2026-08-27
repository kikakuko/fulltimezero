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

  # 달은 언제나 차오른다. 스물여드레의 달도, 앉음의 달도.
  # 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
  test "달이 기운다는 말이 코드에도 문서에도 남아 있지 않다" do
    leftovers = sources.reject { |path| path == Pathname(__FILE__) }
                       .select { |path| path.read.match?(/기운다|기욺|기울\s*고/) }

    assert_empty leftovers.map { |path| path.relative_path_from(Rails.root).to_s },
      "달이 기운다는 서술이 남아 있다"
  end

  test "앉음의 달은 그믐에서 시작한다" do
    sign_in_as users(:one)
    post sittings_path, params: { sitting: { length: "tea", bell: "1" } }
    follow_redirect!

    shade = Nokogiri::HTML(response.body).css(".night .moon ellipse").first

    assert shade, "앉음의 달에 가리개가 없다"
    assert_equal "black", shade["fill"], "그믐이 아니라 이미 밝은 채로 시작한다"
    assert_equal "100.0", shade["rx"], "어둠이 원 전체를 덮고 있지 않다"
  end

  # 온기는 빈도가 낮을수록 진하다. 표정은 정해진 순간에만 떠오른다.
  test "달의 미소는 선 두 획을 넘지 않는다" do
    sign_in_as users(:one)
    post rests_path, params: { rest: { duration: "a_while" } }
    28.times { |i| users(:one).rests.create!(rested_on: users(:one).today - i, duration: "a_moment") }
    follow_redirect!

    assert_select ".smile path", count: 2, message: "미소가 선 두 획을 넘는다"
  end

  test "명상 화면은 성역이다 — 앉는 중에는 표정이 없다" do
    sign_in_as users(:one)
    28.times { |i| users(:one).rests.create!(rested_on: users(:one).today - i, duration: "a_moment") }

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!

    assert_select ".night .smile", false, "앉는 중에 달이 표정을 지었다"
  end

  test "보름에 닿지 않은 날에는 웃지 않는다" do
    sign_in_as users(:one)
    post rests_path, params: { rest: { duration: "a_while" } }
    follow_redirect!

    assert_select ".smile", false, "아무 날에나 웃는다"
  end

  # 숫자 금지의 유일한 예외: 달력의 날짜.
  # 본질상 불가피하므로 허용하되, .date 안에 가둔다. 그 밖으로
  # 한 자리라도 새어 나오면 — 특히 일정의 개수로 — 검사가 깨진다.
  test "날들 화면의 숫자는 달력의 날짜뿐이다" do
    user = users(:one)
    # 사용자가 손으로 적은 말은 사용자의 것이다. 검사하는 것은 앱이
    # 스스로 화면에 두는 숫자뿐이므로, 여기서는 앱의 말만 남긴다.
    %w[치과 회의 저녁 약속 장보기].each { |what| user.plans.create!(planned_on: user.today, what: what) }
    user.clearings.create!(cleared_on: user.today + 1)

    %i[ko en].each do |locale|
      sign_in_as user

      [ days_path(locale: locale), day_path(user.today, locale: locale) ].each do |page|
        get page
        assert_response :success, "#{page} 가 열리지 않는다"

        text = text_outside_dates
        assert_no_match(/\d/, text, "#{page} 의 달력 밖에 숫자가 있다")
        assert_no_match(/!/, text, "#{page} 에 느낌표가 있다")
        assert_no_match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/, text, "#{page} 에 이모지가 있다")

        hosts = response.body.scan(%r{https?://([^/"'\s>]+)}).flatten.uniq
        assert_empty hosts, "#{page} 가 바깥을 부른다: #{hosts.inspect}"
      end

      sign_out
    end
  end

  test "날짜 숫자는 언제나 제자리에 갇혀 있다" do
    sign_in_as users(:one)
    get days_path

    # 제 몫의 글자만 본다. 자식이 지닌 숫자까지 세면 조상이 모두 걸린다.
    loose = Nokogiri::HTML(response.body).css("body *").reject { |node| node.matches?(".date") }
      .select { |node| node.xpath("text()").map(&:text).join[/\d/] }

    assert_empty loose.map { |node| node.to_s.truncate(60) },
      "날짜 숫자가 .date 밖으로 새어 나왔다"
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

    def sources
      %w[app lib config docs test].flat_map { |dir| Rails.root.join(dir).glob("**/*") }
        .select { |path| path.file? && path.extname.in?(%w[.rb .erb .js .css .md .yml]) }
    end

    def text_outside_dates
      page = Nokogiri::HTML(response.body)
      page.css(".date").each(&:remove)
      page.css("body").text.gsub(/\s+/, " ")
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
