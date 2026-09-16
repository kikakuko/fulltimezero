# This app is a raft. — 이 앱도 뗏목이다.
#
# 제4조는 "게이트를 우회하는 경로는 코드에 존재할 수 없다"고 적혀 있다.
# 이 파일은 그 문장을 소스 트리에서 검사한다. 규율이 아니라 자물쇠다.
require "test_helper"
require "tmpdir"

class SilenceTest < ActionDispatch::IntegrationTest
  GATE = "app/models/silence_gate.rb"
  BELL = "app/javascript/controllers/bell_controller.js"

  # 메일이 실제로 나가는 지점은 게이트 안 한 곳뿐이다.
  test "게이트 밖에 발송 경로가 없다" do
    offenders = sources("**/*.rb").select { |path| path.read.match?(/\bdeliver_(now|later)\b/) }

    assert_equal [ GATE ], relative(offenders),
      "게이트를 지나지 않는 발송 경로가 있다. SilenceGate.deliver 로 보내라."
  end

  # 소리를 내는 코드는 종성 컨트롤러 한 파일뿐이다.
  test "종성 밖에 소리를 내는 코드가 없다" do
    offenders = sources("**/*.{js,erb}").select do |path|
      path.read.match?(/new Audio\(|<audio|AudioContext|\.play\(\)/)
    end

    assert_empty relative(offenders) - [ BELL ],
      "종성 컨트롤러 밖에서 소리를 내는 코드가 있다. 게이트를 지나게 하라."
  end

  # 게이트가 등록되어 있지 않으면 위의 모든 규칙이 헛것이다.
  # 실제 발송 경로로 한 통 밀어 넣어 문이 닫혀 있는지 본다.
  class RogueMailer < ApplicationMailer
    def whisper(user)
      mail to: user.email_address, subject: "돌아오세요", body: ""
    end
  end

  # ── 종성 ──────────────────────────────────────────────────────────

  # 기기를 떨게 하는 코드는 한 파일뿐이고, 게이트가 허락할 때만 떤다.
  test "진동은 한 곳에서만, 게이트가 허락할 때만" do
    haptics = "app/javascript/lib/haptics.js"
    shakers = Rails.root.join("app").glob("**/*.{js,erb}").select { |path| path.read.gsub(%r{^\s*//.*$}, "").include?("navigator.vibrate") }

    assert_equal [ haptics ], relative(shakers), "진동이 게이트를 거치지 않는 곳에서 난다"
    assert_match(/if \(!allowed\) return/, Rails.root.join(haptics).read, "허락을 묻지 않고 떤다")
  end

  # 스티뮬러스의 Controller 는 생성자에서 this.context 를 대입한다.
  # 컨트롤러가 같은 이름의 접근자를 두면 그 대입이 터지고, 컨트롤러는
  # 아예 붙지 않는다 — 종이 영영 울리지 않는다. 실제로 그랬다.
  test "컨트롤러가 스티뮬러스의 이름을 가리지 않는다" do
    reserved = %w[context element scope identifier application dispatch]

    controllers.each do |path|
      source = path.read

      reserved.each do |name|
        assert_no_match(/\b(get|set) #{name}\s*\(/, source,
          "#{path.basename} 이 스티뮬러스의 #{name} 을 가린다")
      end
    end
  end

  # 소리는 사용자가 손을 댄 그 순간에 난다. 화면이 바뀐 뒤에 나면
  # 브라우저가 막고, 막힌 소리는 한참 뒤에 엉뚱하게 울린다.
  test "시작종은 누르는 손짓 안에서 울린다" do
    sign_in_as users(:one)
    get new_sitting_path

    # 누르는 손짓이 곧 폼의 submit 이다 — 그 안에서 깨운다. 버튼은 두 길이 나란히
    # 서도록 폼 밖에 있고 form 속성으로 제 폼에 매인다.
    assert_select "form[data-controller=bell][data-action*='submit->bell#open']",
      count: 2, message: "앉기와 무위 모두 손짓 안에서 종을 쳐야 한다"
    assert_select "button[type=submit][form=sitting-form]", count: 1
    assert_select "button[type=submit][form=nothing-form]", count: 1
  end

  test "앉는 자리에서 시작종을 다시 치지 않는다" do
    sign_in_as users(:one)
    post sittings_path, params: { sitting: { length: "tea", bell: "1" } }
    follow_redirect!

    assert_no_match(/bell:open/, response.body,
      "이미 울린 시작종을 화면이 바뀐 뒤에 또 친다")
    assert_select ".night[data-action*='bell:close']"
  end

  test "잠든 컨텍스트의 얼어붙은 시간선에 소리를 예약해 두지 않는다" do
    assert_match(/state === "running"/, bell_source,
      "깨어 있는지 확인하지 않고 소리를 예약한다. 한참 뒤에 울리게 된다.")
    assert_match(/resume\(\)\.then/, bell_source,
      "깨운 뒤에 치는 길이 없다")
  end

  test "종성의 여운은 스무 초 아래로 내려가지 않는다" do
    tail = bell_source[/const TAIL = (\d+)/, 1]&.to_i

    assert tail, "종성 재생기에 여운 길이가 없다"
    assert_operator tail, :>=, 20,
      "여운이 짧다. 기준은 전자 알림음이 아니라 종의 여운이다."
  end

  test "종성은 정수배가 아닌 배음으로 합성한다 — 사인파는 종이 아니다" do
    ratios = bell_source.scan(/ratio: ([\d.]+)/).flatten.map(&:to_f)

    assert_operator ratios.size, :>=, 3, "부분음이 모자라 사인파에 가깝다"
    refute ratios.all? { |ratio| (ratio % 1).zero? },
      "배음이 정수배다. 싱잉볼이 아니라 알림음이 된다."
  end

  test "여운을 뚝 끊지 않는다" do
    assert_match(/linearRampToValueAtTime\(0,/, bell_source,
      "소리를 0으로 데려가는 마지막 기울기가 없다. 여운이 잘린다.")
  end

  test "파일이 있으면 파일이 먼저고, 없으면 합성음으로 운다" do
    helper = Object.new.extend(BellHelper)

    Dir.mktmpdir do |dir|
      sounds = Pathname(dir)

      assert_nil helper.bell_file(:start, dir: sounds), "없는 파일을 찾았다"

      FileUtils.touch(sounds.join("bell-start.ogg"))
      assert_equal "bell-start.ogg", helper.bell_file(:start, dir: sounds)
    end
  end

  test "음원 자리는 비어 있고, 지금은 합성음으로 운다" do
    assert_nil Object.new.extend(BellHelper).bell_file(:start),
      "음원 파일이 들어왔다. docs/SOURCES.md 에 출처와 라이선스를 적어라."
  end

  test "무위는 기본으로 종을 울리지 않는다" do
    sign_in_as users(:one)

    post nothing_path
    follow_redirect!
    assert_select ".void[data-bell-enabled-value=false]"

    post nothing_path, params: { bell: "1" }
    follow_redirect!
    assert_select ".void[data-bell-enabled-value=true]"
  end

  test "울릴지 말지는 화면이 아니라 게이트가 정한다" do
    sign_in_as users(:one)

    stubbing(SilenceGate, :allow?, false) do
      post sittings_path, params: { sitting: { length: "tea", bell: "1" } }
      follow_redirect!
    end

    assert_select ".night[data-bell-enabled-value=false]"
  end

  test "게이트에 밝히지 않은 메일러는 실제 발송에서 죽는다" do
    assert_raises(SilenceGate::Bypass) do
      RogueMailer.whisper(users(:one)).deliver_now
    end
  end

  test "표식 없는 편지는 나가지 못하고 터진다" do
    mail = Mail.new(to: "one@example.com", subject: "부르지 않은 말", body: "")

    assert_raises(SilenceGate::Bypass) do
      SilenceGate::Interceptor.delivering_email(mail)
    end
  end

  test "게이트의 표식은 사용자에게 닿기 전에 지워진다" do
    mail = PasswordsMailer.reset(users(:one))

    assert_equal "password_reset", mail[SilenceGate::STAMP].to_s
    SilenceGate::Interceptor.delivering_email(mail)
    assert_nil mail[SilenceGate::STAMP]
  end

  test "막힌 편지는 예외 없이 조용히 서 있는다" do
    mail = PasswordsMailer.reset(users(:one))

    stubbing(SilenceGate, :allow?, false) do
      SilenceGate::Interceptor.delivering_email(mail)
    end

    refute mail.perform_deliveries, "게이트가 막았는데 편지가 나갔다"
  end

  test "사용자가 청하면 편지 한 통이 나가고, 청하지 않으면 한 통도 나가지 않는다" do
    assert_enqueued_emails 1 do
      post passwords_path(locale: :ko), params: { email_address: users(:one).email_address }
    end

    assert_no_enqueued_emails do
      post passwords_path(locale: :ko), params: { email_address: "nobody@example.com" }
    end
  end

  test "앉는 중에도 사용자가 청한 편지는 답으로서 나간다" do
    user = users(:one)

    stubbing(user, :sitting?, true) do
      assert SilenceGate.allow?(:password_reset, user: user)
    end
  end

  private
    def bell_source = Rails.root.join(BELL).read

    def controllers = Rails.root.join("app/javascript/controllers").glob("*_controller.js") +
                      Rails.root.join("app/javascript/lib").glob("*.js")

    def sources(glob)
      %w[app lib config].flat_map { |dir| Rails.root.join(dir).glob(glob) }.select(&:file?)
    end

    def relative(paths)
      paths.map { |path| path.relative_path_from(Rails.root).to_s }.sort
    end
end
