# This app is a raft. — 이 앱도 뗏목이다.
#
# 게이트를 메일 발송 경로에 못박는다(SPIRIT 제4조).
# 문자열로 등록해 자동 로딩을 방해하지 않는다.
Rails.application.config.action_mailer.interceptors = %w[SilenceGate::Interceptor]
