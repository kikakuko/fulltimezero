# This app is a raft. — 이 앱도 뗏목이다.
class ApplicationController < ActionController::Base
  # 순서 중요: 로케일 around_action 이 인증 before_action 을 감싸야
  # 미인증 리다이렉트도 요청한 로케일 경로로 나간다.
  include Localization
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
