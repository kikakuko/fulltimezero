# This app is a raft. — 이 앱도 뗏목이다.
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/stubbing"
require_relative "test_helpers/copy_locks"
require_relative "test_helpers/webp_info"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # 그림의 크기와 투명은 WebP 머리에서 읽는다 — 재려고 젬을 더하지 않는다.
    include WebpInfo

    # 경전은 앱의 것이라 테스트에도 파일에서 심는다. 값을 테스트에 적지 않는다.
    parallelize_setup { |_worker| Sutra.seed_from(Sutra::HEART_FILE); Abiding.seed_from }

    def heart_sutra = Sutra.find_by(slug: Sutra::HEART) || Sutra.seed_from(Sutra::HEART_FILE)
    def nine_abidings = Abiding.count == Abiding::COUNT ? Abiding.in_order.to_a : Abiding.seed_from

    # Add more helper methods to be used by all tests here...
  end
end

# 모든 경로는 /:locale 아래에 있다. 테스트에서 로케일을 명시하지 않으면 기본 로케일.
Rails.application.routes.default_url_options[:locale] = I18n.default_locale
