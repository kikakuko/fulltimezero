# This app is a raft. — 이 앱도 뗏목이다.
#
# SPIRIT.md 를 코드가 아니라 화면에서 검증한다.
require "test_helper"

class SpiritTest < ActionDispatch::IntegrationTest
  # 금지를 적어 두는 것이 일인 문서는 그 낱말을 불러야 한다.
  # 규칙을 적은 자리와 규칙을 어긴 자리를 섞지 않기 위해 여기만 뺀다.
  RULE_BOOKS = %w[test/integration/spirit_test.rb docs/STATUS.md].freeze

  setup { heart_sutra }

  OPEN_PAGES = %i[gate_path new_user_path new_session_path new_password_path guide_path privacy_path].freeze
  # 날들은 여기에 없다 — 달력의 날짜는 숫자 금지의 유일한 예외이고,
  # 그 화면은 따로 검사한다(「날들 화면의 숫자는 달력의 날짜뿐이다」).
  SIGNED_IN_PAGES = %i[today_path new_rest_path settings_path new_sitting_path
                       new_copying_path pagoda_path].freeze

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

    I18n.available_locales.each do |locale|
      post sittings_path(locale: locale), params: { sitting: { length: "incense", bell: "1" } }
      follow_redirect!
      assert_quiet_screen "앉는 중", locale

      post nothing_path(locale: locale), params: { bell: "1" }
      follow_redirect!
      assert_quiet_screen "무위", locale
    end
  end

  # 자리 넷 — 오늘 · 날들 · 앉기 · 사경. 도상 넷(달 · 미륵 · 코끼리 · 탑)과
  # 하나씩 마주 선다. 늘 아래에 있되, 몰입 화면에는 없다.
  test "네 개의 문이 늘 아래에 있다" do
    sign_in_as users(:one)

    [ today_path, days_path, new_sitting_path, new_copying_path ].each do |page|
      get page

      assert_select "nav.doors a.door", count: 4, message: "#{page} 에 문이 넷이 아니다"
      assert_select "nav.doors a.door.here", count: 1, message: "#{page} 에서 선 자리가 하나가 아니다"
    end
  end

  test "몰입 화면은 성역이다 — 문이 없다" do
    user = users(:one)
    sign_in_as user

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!
    assert_select "nav.doors", false, "앉는 중에 문이 서 있다"

    post nothing_path
    follow_redirect!
    assert_select "nav.doors", false, "무위에 문이 서 있다"

    post rests_path, params: { rest: { duration: "a_while" } }
    follow_redirect!
    assert_select "nav.doors", false, "오늘 몫이 끝난 자리에 문이 서 있다"
  end

  test "들어오기 전에는 문이 보이지 않는다" do
    get gate_path

    assert_select "nav.doors", false
  end

  # 달은 언제나 차오른다. 스물여드레의 달도, 앉음의 달도.
  # 시간의 소진이 아니라 고요의 익어감이 이 앱의 문법이다.
  test "달이 기운다는 말이 코드에도 문서에도 남아 있지 않다" do
    leftovers = written.select { |path| path.read.match?(/기운다|기욺|기울\s*고/) }

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

  # 달에는 이목구비가 없다. 호선 둘을 얹는 순간 그것은 미소 띤 달이
  # 아니라 얼굴이 되고, 얼굴이 되는 순간 의인화가 된다.
  # 달은 표정이 아니라 빛으로 말한다.
  #
  # 이 자물쇠는 달을 그리는 파일에만 걸린다(SPIRIT §7, 2026-09-15).
  # 파장동 미륵은 마을 사람들이 덧칠해 만든 얼굴이 곧 정체성이라,
  # 얼굴을 빼면 미륵이 아니다.
  MOON_COMPONENTS = %w[
    app/helpers/moon_helper.rb
    app/javascript/controllers/sitting_controller.js
  ].freeze

  test "달에 얼굴을 그리지 않는다" do
    # 주석은 왜 그리지 않는지를 적은 자리이므로 걷어내고, 코드만 본다.
    # 밑줄도 낱말의 경계로 친다. \b 만 쓰면 moon_face 같은 이름이 새어 나간다.
    faces = /(?:\b|_)(?:smiles?|faces?|eyes?|mouths?)(?:\b|_)|눈매|입매/i

    moon = MOON_COMPONENTS.map { |file| Rails.root.join(file) }
    assert moon.all?(&:exist?), "달을 그리는 파일이 옮겨졌다. MOON_COMPONENTS 를 고쳐라."

    offenders = moon.select { |path| strip_comments(path).match?(faces) }

    assert_empty offenders.map { |path| path.relative_path_from(Rails.root).to_s },
      "달에 표정을 그리는 코드가 남아 있다"
  end

  # 온기는 빈도가 낮을수록 진하다. 월광은 정해진 순간에만 핀다.
  test "월광은 보름에 닿은 그 순간에만 핀다" do
    user = users(:one)
    sign_in_as user

    post rests_path, params: { rest: { duration: "a_while" } }
    follow_redirect!
    assert_select ".moonlight", false, "아무 날에나 빛이 핀다"

    27.times { |i| user.rests.create!(rested_on: user.today - (i + 1), duration: "a_moment") }
    post rests_path, params: { rest: { duration: "a_while" } }
    follow_redirect!

    assert_select ".moon.moonlight", count: 1, message: "보름에 닿았는데 빛이 없다"
    assert_match I18n.t("moon.full"), visible_text
  end

  # 빛무리는 어두운 바탕에서만 성립하는 물리다 — 낮하늘의 보름달에는
  # 광배가 없다. 어두운 바탕은 문과 몰입 화면뿐이고(SPIRIT §2), 몰입
  # 화면은 성역이라 빛이 피지 않는다. 그래서 월광은 언제나 밝은 바탕에서
  # 오고, 빛무리는 어디에도 그려지지 않는다. 훗날 다시 그린다면 어두운
  # 자리 안에서만.
  test "빛무리는 도상에 없고, 밝은 바탕에서는 피지 않는다" do
    user = users(:one)
    sign_in_as user
    27.times { |i| user.rests.create!(rested_on: user.today - (i + 1), duration: "a_moment") }
    post rests_path, params: { rest: { duration: "a_while" } }
    follow_redirect!

    assert_select ".halo", false, "빛무리가 도상에 박혀 있어 밝은 바탕에서도 그려진다"

    css = Rails.root.join("app/assets/tailwind/application.css").read.gsub(%r{/\*.*?\*/}m, "")
    css.scan(/([^{}]+)\{([^{}]*moonlight-halo[^{}]*)\}/).each do |selector, _|
      next if selector.strip.start_with?("@keyframes")

      selector.split(",").map(&:strip).each do |one|
        assert_match(/\A\.(?:night|void|threshold)\b/, one, "빛무리가 밝은 바탕에서 핀다: #{one}")
      end
    end
  end

  test "명상 화면은 성역이다 — 앉는 중에는 빛도 표정도 없다" do
    user = users(:one)
    sign_in_as user
    28.times { |i| user.rests.create!(rested_on: user.today - i, duration: "a_moment") }

    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!

    assert_select ".night .moonlight", false, "앉는 중에 빛이 피었다"
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

    I18n.available_locales.each do |locale|
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
  # 주소는 카피가 아니다 — 읽히는 글이 아니라 눌러서 나가는 문의
  # 손잡이다. 화면에 글자로 나타나는 것에만 숫자 금지가 걸린다.
  ADDRESSES = %w[link].freeze

  test "카피 어디에도 숫자가 없다" do
    %w[ko en].each do |locale|
      copy = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)

      flatten_copy(copy).each do |line|
        assert_no_match(/\d/, line, "#{locale} 카피에 숫자가 있다: #{line.inspect}")
      end
    end
  end

  # 이 앱은 쉼을 가르치지 않는다 — 쉬는 마음이 형상을 얻게 할 뿐이다(§5).
  # 인용 원문은 예외다. 옛글의 낱말은 옛글의 것이다.
  test "카피가 쉼을 가르치지 않는다 — 수행·훈련·단계의 말이 없다" do
    I18n.available_locales.map(&:to_s).each do |locale|
      copy = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)

      flatten_copy(copy).reject { |line| line.start_with?("「") }.each do |line|
        assert_no_match CopyLocks.pattern(:teaching, locale), line, "#{locale} 카피가 가르친다: #{line[0, 60]}"
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

  # 화면이 스스로 바깥을 부르지 않는다.
  #
  # 링크 하나는 요청이 아니다 — 사용자가 눌러야만 열리는 문이다.
  # 그러나 자동으로 실려 오는 것(그림·글꼴·스크립트)과 미리 이어 두는
  # 것(preconnect·prefetch·preload)은 사용자가 부르지 않았는데도
  # 나가는 요청이므로 하나도 둘 수 없다.
  test "어느 화면도 제3자에게 요청을 보내지 않는다" do
    each_page { |page, locale| assert_no_outward_requests(page, locale) }
  end

  test "바깥으로 나가는 문은 눌러야만 열린다" do
    outward = false

    I18n.available_locales.each do |locale|
      GuideController::CHAPTERS.each do |chapter|
        get guide_chapter_path(chapter, locale: locale)
        assert_no_outward_requests("guide/#{chapter}", locale)

        Nokogiri::HTML(response.body).css("a[href^='http']").each do |door|
          outward = true
          assert_equal "_blank", door["target"], "바깥 문이 이 창을 덮어쓴다: #{door["href"]}"
          assert_includes door["rel"].to_s, "noopener", "바깥 문에 noopener 가 없다"
          assert_equal "false", door["data-turbo"], "터보가 바깥 문을 미리 당겨 온다"
        end
      end
    end

    assert outward, "출전이 원문으로 이어지지 않는다"
  end

  test "쉼을 기록해도 알림은 한 통도 나가지 않는다" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      post rests_path(locale: :ko), params: { rest: { duration: "a_while" } }
      get today_path(locale: :ko)
      get moon_path(locale: :ko)
    end
  end

  # 탑은 언제든 볼 수 있다. 세는 것을 막는 일은 화면이 한다 —
  # 숫자도, 빈 칸도, 몇 층인지도 없다. 쓴 자리만 그린다.
  test "탑 화면에는 숫자도 빈 칸도 층 표시도 없다" do
    user = users(:one)
    rows = heart_sutra.chars.where(pos: 1..3).map do |char|
      { user_id: user.id, sutra_char_id: char.id, copied_on: user.today - (4 - char.pos),
        glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
    end
    Copying.insert_all!(rows)
    sign_in_as user

    I18n.available_locales.each do |locale|
      get pagoda_path(locale: locale)

      assert_no_match(/\d/, visible_text, "탑 화면에 숫자가 있다")
      assert_no_match(/층|floor|layer|남은|남았|left|remaining/i, visible_text, "탑 화면이 층을 세거나 남은 것을 말한다")
    end

    scene = JSON.parse(css_select("[data-pagoda-scene-value]").first["data-pagoda-scene-value"])
    assert_equal 3, scene["cells"].size, "쓰지 않은 칸의 자리가 화면으로 나갔다"
    assert scene["cells"].none? { |cell| cell["fresh"] }, "보는 자리에 방금 올린 자가 있다"
  end

  # 「쉼의 안내」에 인용문이 들어온다면 그 출처는 CC0 원문뿐이어야 한다.
  test "쉼의 안내에는 출처 없는 인용문이 없다" do
    sources = File.read(Rails.root.join("docs/SOURCES.md"))
    assert_match(/CC0/, sources, "출처 문서에 라이선스 원칙이 없다")

    copy = I18n.available_locales.flat_map { |l| flatten_copy(I18n.t("guide", locale: l)) }.join(" ")
    quotations = copy.scan(/[“「『]([^”」』]+)[”」』]/).flatten

    # 출처 문서에서는 긴 인용문이 여러 줄로 접혀 있다. 줄바꿈이 출처
    # 확인을 무력화해서는 안 되므로 양쪽의 공백을 고르고 견준다.
    haystack = flatten_spaces(sources.gsub(/^\s*>\s?/, ""))

    quotations.each do |quotation|
      assert_includes haystack, flatten_spaces(quotation),
        "인용문 #{quotation.inspect} 의 출처가 docs/SOURCES.md 에 없다"
    end
  end

  private
    # 링크의 href 는 문이므로 세지 않는다. 그 밖에 바깥 주소가 실려
    # 있으면 — src 든 미리 잇는 태그든 — 그것은 부르지 않은 요청이다.
    def assert_no_outward_requests(page, locale)
      page_html = Nokogiri::HTML(response.body)
      page_html.css("a[href]").each { |link| link.remove_attribute("href") }

      hosts = page_html.to_s.scan(%r{https?://([^/"'\s>]+)}).flatten.uniq
      assert_empty hosts, "#{page}(#{locale}) 화면이 바깥을 부른다: #{hosts.inspect}"

      # 임포트맵이 제 파일을 미리 잇는 것은 바깥이 아니다. 바깥 주소를
      # 미리 잇는 것만 막는다.
      hints = %w[preconnect dns-prefetch prefetch preload modulepreload]
      early = Nokogiri::HTML(response.body).css("link[rel]").select do |link|
        link["rel"].to_s.split.intersect?(hints) && link["href"].to_s.start_with?("http")
      end

      assert_empty early.map { |link| link["href"] },
        "#{page}(#{locale}) 가 바깥을 미리 잇는다"
    end

    def flatten_spaces(text) = text.gsub(/\s+/, " ").strip

    def strip_comments(path)
      path.read
          .gsub(%r{/\*.*?\*/}m, "")            # css
          .gsub(%r{^\s*(#|//).*$}, "")          # ruby · js
          .gsub(%r{<%#.*?%>}m, "")              # erb
    end

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

    # 규칙을 적은 자리를 뺀 나머지 — 규칙을 지켜야 하는 자리들.
    def written
      sources.reject { |path| path.relative_path_from(Rails.root).to_s.in?(RULE_BOOKS) }
    end

    def text_outside_dates
      page = Nokogiri::HTML(response.body)
      page.css(".date").each(&:remove)
      page.css("body").text.gsub(/\s+/, " ")
    end

    def flatten_copy(node)
      case node
      when Hash
        node.reject { |key, _| key.to_s.in?(ADDRESSES) }.values.flat_map { |v| flatten_copy(v) }
      when Array then node.flat_map { |v| flatten_copy(v) }
      else [ node.to_s ]
      end
    end

    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end

    def each_page
      I18n.available_locales.each do |locale|
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
