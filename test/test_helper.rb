# This app is a raft. — 이 앱도 뗏목이다.
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# 모든 경로는 /:locale 아래에 있다. 테스트에서 로케일을 명시하지 않으면 기본 로케일.
Rails.application.routes.default_url_options[:locale] = I18n.default_locale
