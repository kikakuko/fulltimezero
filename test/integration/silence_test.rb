# This app is a raft. — 이 앱도 뗏목이다.
#
# 제4조는 "게이트를 우회하는 경로는 코드에 존재할 수 없다"고 적혀 있다.
# 이 파일은 그 문장을 소스 트리에서 검사한다. 규율이 아니라 자물쇠다.
require "test_helper"

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
    def sources(glob)
      %w[app lib config].flat_map { |dir| Rails.root.join(dir).glob(glob) }.select(&:file?)
    end

    def relative(paths)
      paths.map { |path| path.relative_path_from(Rails.root).to_s }.sort
    end
end
