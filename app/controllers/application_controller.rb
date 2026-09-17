# This app is a raft. — 이 앱도 뗏목이다.
class ApplicationController < ActionController::Base
  # 순서 중요: 로케일 around_action 이 인증 before_action 을 감싸야
  # 미인증 리다이렉트도 요청한 로케일 경로로 나간다.
  include Localization
  include Authentication
  include Throttling

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 매일 지나는 문 — 앱을 열 때마다 첫째 문의 빛이 짧게 다가온다.
  # 「앱을 연다」는 것을 한동안 오지 않다가 돌아온 것으로 읽는다.
  # 화면을 옮겨 다니는 사이에는 다시 지나가지 않는다.
  DAILY_DOOR_AFTER = 30.minutes

  helper_method :daily_door_due?
  after_action :remember_seen

  private
    def daily_door_due?
      return @daily_door_due if defined?(@daily_door_due)

      @daily_door_due = authenticated? && Current.user.onboarded? && Current.user.daily_door &&
                        !is_a?(OnboardingController) && away_long_enough?
    end

    def away_long_enough?
      seen = session[:seen_at]
      seen.nil? || Time.zone.at(seen) < DAILY_DOOR_AFTER.ago
    end

    def remember_seen
      session[:seen_at] = Time.current.to_i if authenticated?
    end
end
