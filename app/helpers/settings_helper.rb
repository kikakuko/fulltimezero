# This app is a raft. — 이 앱도 뗏목이다.
module SettingsHelper
  # 시간대 목록에는 오프셋(+09:00)을 보이지 않는다 — 화면에 숫자를 두지 않는다.
  def time_zone_choices(user)
    zones = ActiveSupport::TimeZone::MAPPING.values.reject { |z| z.start_with?("Etc/") }
    (zones + [ user.time_zone ]).compact.uniq.sort
  end
end
