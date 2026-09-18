require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # 앞의 프록시(kamal-proxy)가 SSL 을 끝낸다. 도메인은 환경변수로 온다 — 코드에 적지 않는다.
  config.assume_ssl = true
  config.force_ssl = true
  # 살았는지 묻는 자리는 https 로 돌리지 않는다.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # 편지 — 이 앱이 먼저 보내는 메일은 없다. 사용자가 청한 비밀번호 재설정뿐이다(§4의 주석).
  # 보내는 곳은 정해지지 않았으므로 값은 모두 환경변수로 받는다. 비밀값은 코드에 적지 않는다.
  #   MAIL_HOST      링크에 쓰는 도메인(예: 도메인 그대로)
  #   MAIL_FROM      보내는 이 주소
  #   SMTP_ADDRESS   메일 서버 주소
  #   SMTP_PORT      기본 587
  #   SMTP_USER_NAME · SMTP_PASSWORD   메일 회사가 준 것(.kamal/secrets 로 넣는다)
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV.fetch("MAIL_HOST", ENV.fetch("APP_HOST", "localhost")) }
  config.action_mailer.default_options = { from: ENV.fetch("MAIL_FROM", "no-reply@#{ENV.fetch('APP_HOST', 'localhost')}") }
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV["SMTP_USER_NAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # 이 주소로 온 것만 받는다. 도메인은 환경변수로 온다(APP_HOST).
  config.hosts = [ ENV.fetch("APP_HOST", "localhost"), "www.#{ENV.fetch('APP_HOST', 'localhost')}" ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
