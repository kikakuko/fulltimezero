# This app is a raft. — 이 앱도 뗏목이다.
#
# 화면을 열어 보는 손 — 자물쇠 둘(약속 · 결)이 함께 쓴다. 여는 화면의 목록과 글자를 꺼내는
# 방법을 한 곳에 둔다. 무엇을 금지하는지는 자물쇠가 적고, 여기는 어떻게 보는지만 적는다.
module Screens
  RULE_BOOKS = %w[test/locks/promise/spirit_promise_test.rb test/locks/form/spirit_form_test.rb
                  test/test_helpers/screens.rb docs/STATUS.md].freeze

  # 문 셋은 계정 없이 지난다 — 문이 랜딩이다.
  OPEN_PAGES = %i[threshold_path threshold_naming_path threshold_breath_path new_user_path new_session_path
                  new_password_path guide_path privacy_path].freeze

  # 날들은 여기에 없다 — 달력의 날짜는 숫자 금지의 유일한 예외이고,
  # 그 화면은 따로 검사한다(「날들 화면의 숫자는 달력의 날짜뿐이다」).
  SIGNED_IN_PAGES = %i[today_path new_rest_path settings_path new_sitting_path
                       new_copying_path pagoda_path].freeze

  # 주소는 카피가 아니다 — 읽히는 글이 아니라 눌러서 나가는 문의
  # 손잡이다. 화면에 글자로 나타나는 것에만 숫자 금지가 걸린다.
  ADDRESSES = %w[link].freeze

  # 빌려온 표기 — 이용조건이 「이대로 적으라」고 정한 글이다. 공공누리의 권장
  # 양식에는 유형과 연도가 숫자로 들어 있고, 고치면 그것은 더 이상 그 양식이
  # 아니다. 앱이 하는 말이 아니라 옮겨 적는 글이므로 카피의 숫자 금지 밖에 둔다 —
  # 인용 원문이 §5 의 예외인 것과 같은 결이다.
  # 화면에서는 .credit 안에만 설 수 있다(spirit_form_test 가 가둔다).
  BORROWED = %w[notice].freeze

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
      node.reject { |key, _| key.to_s.in?(ADDRESSES + BORROWED) }.values.flat_map { |v| flatten_copy(v) }
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
