# This app is a raft. — 이 앱도 뗏목이다.
#
# SPIRIT 의 결을 화면에서 검증한다 — 방향을 틀면 풀 수 있는 것들.
# 아라비아 숫자 · 이모지 · 느낌표가 화면에 없다. 문 넷의 자리, 달의 도상.
# 사람을 재는 것과 바깥을 부르는 것은 약속 쪽이다 — test/locks/promise/spirit_promise_test.rb.
require "test_helper"
require_relative "../../test_helpers/copy_locks"

class SpiritFormTest < ActionDispatch::IntegrationTest
  include Screens

  setup { heart_sutra }

  # 화면에 아라비아 숫자가 보이지 않는다. 사람을 재는 것(퍼센트 · 연속 · 분)은 「약속」 쪽.
  test "어느 화면에도 아라비아 숫자가 보이지 않는다" do
    each_page do |page, locale|
      assert_no_match(/\d/, visible_text, "#{page}(#{locale}) 화면에 숫자가 보인다")
    end
  end

  test "앉는 중에도 무위에도 아라비아 숫자가 없다" do
    sign_in_as users(:one)

    I18n.available_locales.each do |locale|
      post sittings_path(locale: locale), params: { sitting: { length: "incense", bell: "1" } }
      follow_redirect!
      assert_no_match(/\d/, visible_text, "앉는 중(#{locale}) 화면에 숫자가 보인다")

      post nothing_path(locale: locale), params: { bell: "1" }
      follow_redirect!
      assert_no_match(/\d/, visible_text, "무위(#{locale}) 화면에 숫자가 보인다")
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
  # 달에는 이목구비가 없다. 호선 둘을 얹는 순간 그것은 미소 띤 달이 아니라 얼굴이 되고,
  # 얼굴이 되는 순간 의인화가 된다. 달은 표정이 아니라 빛으로 말한다.
  # 이 자물쇠는 달을 그리는 파일에만 걸린다(SPIRIT §7, 2026-09-15). 파장동 미륵은 마을
  # 사람들이 덧칠해 만든 얼굴이 곧 정체성이라, 얼굴을 빼면 미륵이 아니다.
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
  test "탑 화면에 숫자가 없다" do
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
    end
  end
end
