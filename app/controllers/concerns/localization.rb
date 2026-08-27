# This app is a raft. — 이 앱도 뗏목이다.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&)
      I18n.with_locale(requested_locale, &)
    end

    def requested_locale
      params[:locale].presence_in(User::LOCALES) ||
        Current.user&.locale ||
        I18n.default_locale
    end

    def default_url_options
      { locale: I18n.locale }
    end
end
