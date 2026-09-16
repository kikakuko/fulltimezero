# This app is a raft. — 이 앱도 뗏목이다.
require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fulltimezero
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # 국제적 웹앱: 경로 스코프 /:locale 로 여기 적힌 언어만 받는다.
    # 언어의 목록은 여기 한 곳에만 있다 — 경로 · 계정의 언어 · 화면 아래의
    # 전환이 모두 여기서 나온다. 셋째 언어는 여기에 더하고, 그 언어의
    # 로케일 파일 · 금지어 목록 · 데이터 칸이 갖춰져야 테스트가 통과한다.
    config.i18n.available_locales = %i[ ko en ]
    config.i18n.default_locale = :ko
    config.i18n.fallbacks = [ :en ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
