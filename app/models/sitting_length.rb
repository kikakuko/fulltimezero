# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉음의 길이 — 그 자리의 설정이지 기록이 아니다. 저장되지 않는다.
#
# 낱말은 쉼의 길이(Rest::DURATIONS)와 겹치지 않는 별도 계열로 둔다.
# 향 한 대·차 한 잔은 시계 이전의 전통이 시간을 재던 단위다 —
# 숫자 없이 길이를 말하는 법을 전통이 이미 발명해 두었다.
# 화면에도, 저장에도, 스크린리더에도 숫자는 나타나지 않는다.
# 분은 오직 이 표 안에만 있고, 브라우저에게 초로 한 번 건네질 뿐이다.
class SittingLength
  MINUTES = {
    "short" => 3,      # 짧게 앉기
    "tea" => 10,       # 차 한 잔의 앉음
    "incense" => 20,   # 향 한 대의 앉음
    "long" => 30,      # 긴 앉음
    "open" => nil      # 정함 없이 — 끝은 사용자가 정한다
  }.freeze

  NAMES = MINUTES.keys.freeze
  DEFAULT = "tea"

  attr_reader :name

  def initialize(name)
    @name = NAMES.include?(name.to_s) ? name.to_s : DEFAULT
  end

  # 정함 없이 앉으면 닿을 목표 시점이 없다.
  def open? = MINUTES[name].nil?

  def seconds = MINUTES[name].to_i * 60

  # 새로고침해도 앉은 자리가 처음부터 다시 시작하지 않도록,
  # 앉은 만큼을 브라우저에 건넨다. 달은 그 자리에서 이어 차오른다.
  def seconds_done(since)
    done = (Time.current - since).round

    open? ? done : done.clamp(0, seconds)
  end
end
