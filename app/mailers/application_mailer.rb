# This app is a raft. — 이 앱도 뗏목이다.
#
# 모든 메일은 자신이 어떤 갈래인지 게이트에 밝혀야 한다.
# 밝히지 않은 메일은 SilenceGate::Interceptor 에서 죽는다.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  before_action :stamp_for_gate

  class << self
    def gate(kind)
      SilenceGate.rule_for(kind) # 게이트가 모르는 갈래면 여기서 터진다.
      @gate_kind = kind
    end

    def gate_kind = @gate_kind
  end

  private
    def stamp_for_gate
      kind = self.class.gate_kind
      headers[SilenceGate::STAMP] = kind.to_s if kind
    end
end
