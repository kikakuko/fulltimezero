# This app is a raft. — 이 앱도 뗏목이다.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :guests_only_look
    helper_method :authenticated?, :guest?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    # 손님은 보되 쓰지 못한다. 저장되는 길은 하나도 열려 있지 않다 — 길이 없으므로
    # 404 다. 화면에서 손짓을 숨기는 것만으로는 모자라다.
    def guests_only_look
      head :not_found if guest? && !request.get? && !request.head?
    end

    def authenticated?
      resume_session || resume_guest
    end

    def require_authentication
      resume_session || resume_guest || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # 손님 — 계정이 없고 세션도 없다. 가입이 닫혀 있는 동안 씨앗을 함께 본다.
    def resume_guest
      Current.guest ||= Guest.user
    end

    # 인증을 건너뛰는 화면(문 셋 같은)에서도 손님인지 먼저 가린다 — 가리지 않으면
    # 그 화면의 쓰는 길이 손님에게 열린 채로 남는다.
    def guest?
      resume_session
      Current.session.nil? && resume_guest.present?
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      # 가입이 닫혀 있으면 로그인의 길도 없다 — 한 줄로 말하는 화면으로 보낸다.
      return redirect_to not_yet_path(locale: I18n.locale) if SignupGate.closed?

      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path(locale: I18n.locale)
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || today_url
    end

    def start_new_session_for(user)
      # 어디서, 무엇으로 들어왔는지는 적지 않는다. 이메일 말고는 모으지 않는다(§4).
      user.sessions.create!.tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
