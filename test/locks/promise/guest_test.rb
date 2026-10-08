# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 손님은 보되 쓰지 못한다 — 약속이다.
#
# §3 은 「쌓인 것은 무너지지 않는다」고 했다. 손님이 적었다가 사라지면 배신이다.
# 그래서 아예 쓰지 못하게 하고, 그것을 처음에 한 줄로 밝힌다. 말없이 무너뜨리는
# 것이 §3 이 막는 일이고, 미리 밝히는 것은 다르다.
#
# 손님에게는 이메일을 묻지 않는다. 손님의 흔적은 남지 않는다 — 세션도 쿠키도.
class GuestTest < ActionDispatch::IntegrationTest
  include Screens

  setup do
    heart_sutra
    nine_abidings
    @seed = User.create!(email_address: Guest::SEED, password: SecureRandom.hex(16),
                         onboarded_at: 60.days.ago, locale: "ko", time_zone: "Asia/Seoul")
    @seed.rests.create!(rested_on: @seed.today - 3, duration: Rest::DURATIONS.first)
    @seed.clearings.create!(cleared_on: @seed.today - 7)
  end

  test "가입이 닫혀 있는 동안 계정 없이도 안을 본다" do
    closed do
      get today_path
      assert_response :success, "손님이 마당에 들어서지 못한다"

      assert_match I18n.t("guest.line"), visible_text, "손님임을 밝히는 한 줄이 없다"
    end
  end

  test "저장되는 길이 하나도 열려 있지 않다" do
    closed do
      writing_routes.each do |verb, path|
        public_send(verb, path)

        assert_response :not_found, "손님이 #{verb.upcase} #{path} 로 쓸 수 있다(#{response.status})"
      end
    end
  end

  test "손님이 지나가도 쌓인 것이 늘지 않는다" do
    closed do
      before = [ Rest.count, Sitting.count, Clearing.count, Copying.count, Plan.count, User.count ]

      get today_path
      post rests_path, params: { rest: { duration: "short" } }
      patch day_path(@seed.today)
      post copyings_path, params: { copying: { glyph_paths: "[[[0.5,0.5]]]" } }

      assert_equal before, [ Rest.count, Sitting.count, Clearing.count, Copying.count, Plan.count, User.count ],
        "손님이 지나간 자리에 무언가 쌓였다"
    end
  end

  test "손님의 흔적이 남지 않는다 — 세션도 쿠키도" do
    closed do
      sessions = Session.count

      get today_path
      get days_path

      assert_equal sessions, Session.count, "손님에게 세션이 생겼다"
      assert_nil cookies[:session_id].presence, "손님에게 쿠키가 심겼다"
    end
  end

  test "손님에게 이메일을 묻지 않는다" do
    closed do
      %i[today_path days_path new_rest_path new_copying_path settings_path pagoda_path].each do |screen|
        get public_send(screen)

        assert_select "input[type=email]", false, "#{screen} 이 손님에게 이메일을 묻는다"
        assert_select "input[type=password]", false, "#{screen} 이 손님에게 비밀번호를 묻는다"
      end
    end
  end

  test "쌓는 손짓이 손님에게 보이지 않는다" do
    closed do
      %i[today_path days_path new_rest_path new_copying_path settings_path].each do |screen|
        get public_send(screen)

        assert_select "form", false, "#{screen} 에 손님이 쓸 수 있는 폼이 보인다"
      end
    end
  end

  # 문 셋은 손님에게도 열린다 — 다만 보내는 손짓이 아니라 가는 문이다. 적을 것이 없으니
  # 첫째 문에서 한 자리로 지난다: 「들어간다」 하나로 빛이 불이문까지 가고 마당이다(GET).
  # 둘째 · 셋째 문의 한 줄은 같은 자리에 떠오르고, 그 주소로 오면 첫째 문이다. 지나도
  # 씨앗은 그대로다.
  test "손님은 첫째 문에서 한 자리로 지난다 — 보내지 않고 간다" do
    closed do
      before = [ @seed.reload.onboarded_at, @seed.what_moves ]

      get threshold_path
      assert_select ".threshold--stop[data-controller~=passage] button.button-primary[data-action='click->passage#enter']", count: 1
      assert_select "form[method=get][action=?][data-passage-target=gate]", today_path(locale: :ko), count: 1
      assert_select "form[method=post]", false, "첫째 문에 손님이 보낼 폼이 있다"
      assert_select "a[href=?]", threshold_naming_path, false, "손님을 둘째 문으로 보낸다"
      %w[stop naming breath].each do |door|
        assert_select ".passage__lines .gates__line.passage__line--#{door}", count: 1
      end
      assert_select "input[name='user[what_moves]']", false, "손님에게 한 줄을 묻는다"
      assert_select "a.button-quiet[href=?]", today_path(locale: :ko), count: 1

      get threshold_naming_path
      assert_redirected_to threshold_path
      get threshold_breath_path
      assert_redirected_to threshold_path

      assert_equal before, [ @seed.reload.onboarded_at, @seed.what_moves ], "손님이 문을 지나자 씨앗이 바뀌었다"
    end
  end

  # 문이 랜딩이다 — 손님도 첫째 문부터 들어온다. 지나면 그다음부터는 마당이다.
  test "손님은 첫째 문에서 들어오고, 지나면 마당이다" do
    closed do
      get gate_path
      assert_redirected_to threshold_path, "손님이 문을 건너뛰고 마당에 떨어진다"

      get today_path
      assert_response :success

      get gate_path
      assert_redirected_to today_path(locale: :ko), "문을 지났는데 다시 문을 세운다"
      assert_nil cookies[:session_id].presence, "손님에게 로그인 쿠키가 심겼다"
    end
  end

  # 가입이 열리면 구경하는 자리는 사라진다 — 그때는 저마다의 자리가 생긴다.
  test "가입이 열리면 손님의 자리가 없다" do
    with_env("SIGNUPS", "true") do
      assert_not Guest.open?

      get today_path
      assert_redirected_to new_session_path(locale: :ko)
    end
  end

  private
    def closed(&block) = with_env("SIGNUPS", "false", &block)

    def with_env(name, value)
      was = ENV[name]
      ENV[name] = value
      yield
    ensure
      ENV[name] = was
    end

    # 라우트에 적힌 모든 쓰는 길. 새 길이 생기면 여기에 저절로 들어온다.
    def writing_routes
      Rails.application.routes.routes.filter_map do |route|
        verbs = route.verb.to_s.scan(/GET|POST|PATCH|PUT|DELETE/)
        next if verbs.empty? || verbs == [ "GET" ]

        path = route.path.spec.to_s.sub(/\(\.:format\)\z/, "")
        next if path.include?("*") || path.include?("rails/")

        path = path.gsub(":locale", "ko").gsub(/:\w+/, "1")
        [ (verbs - [ "GET" ]).first.downcase.to_sym, path ]
      end.uniq
    end
end
