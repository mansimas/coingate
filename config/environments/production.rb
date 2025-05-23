require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.action_controller.default_url_options = {
    host: ENV.fetch('RENDER_EXTERNAL_HOSTNAME') { ENV.fetch('PROXY_HOST') },
    protocol: ENV.fetch('PROXY_PROTOCOL') { 'https' }
  }

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = false
  config.assume_ssl = true
  config.force_ssl = true

  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
end
