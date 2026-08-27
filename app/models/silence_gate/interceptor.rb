# This app is a raft. — 이 앱도 뗏목이다.
#
# 게이트의 마지막 문. 발송 직전에 모든 메일이 여기를 지난다.
#
# 표식이 없는 메일은 나가지 못한다 — 조용히 새는 대신 터진다.
# 발송이 큐에 들어간 뒤 시간이 흘렀을 수 있으므로, 여기서 한 번 더
# 게이트에 묻는다.
class SilenceGate::Interceptor
  def self.delivering_email(message)
    kind = message[SilenceGate::STAMP]&.to_s

    if kind.blank?
      raise SilenceGate::Bypass,
        "게이트를 지나지 않은 메일이다: #{message.subject.inspect}. " \
        "메일러에 `gate :kind` 를 밝혀라."
    end

    message[SilenceGate::STAMP] = nil

    user = User.find_by(email_address: Array(message.to).first)
    message.perform_deliveries = false unless SilenceGate.allow?(kind, user: user)
  end
end
