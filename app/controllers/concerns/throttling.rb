# This app is a raft. — 이 앱도 뗏목이다.
#
# 들어오기·가입·재설정 시도를 IP 가 아니라 이메일로 센다.
#
# Rails 의 rate_limit 는 기본으로 request.remote_ip 를 센다. 이 앱은
# 이메일 말고 아무것도 모으지 않는다고 약속했으므로(SPIRIT §4), IP 를
# 보지 않는다. 캐시에 잠시 남는 것도 이메일 그 자체가 아니라 지문(해시)
# 이다 — 운영 캐시는 데이터베이스에 있어서, 오타 난 남의 이메일까지
# 날것으로 남겨 두지 않기 위해서다.
#
# 주의: 이메일로 세면 한 계정에 대한 무차별 대입은 막지만, 여러
# 계정을 번갈아 두드리는 시도는 막지 못한다. IP 를 보지 않는 대가다.
module Throttling
  extend ActiveSupport::Concern

  def self.fingerprint(email) = Digest::SHA256.hexdigest(email.to_s.strip.downcase)

  private
    def throttle_key = Throttling.fingerprint(submitted_email)

    def submitted_email = params[:email_address] || params.dig(:user, :email_address)
end
