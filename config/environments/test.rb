# config/environments/test.rb

require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  # This relates to Action Dispatch middleware. Keep as it's standard for test env,
  # even if you don't serve files yourself, as middleware might interact with it.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store # Null store is appropriate for API tests

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  # Keep as this configures exception handling in the test environment.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  # Keep this as it's necessary for testing API endpoints without CSRF tokens.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  # Remove or comment out as Active Storage is not loaded in your API-only setup.
  # config.active_storage.service = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr # Keep for development/test feedback

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise # Keep for catching unwanted deprecations

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = [] # Keep if you use this feature

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true # Keep if you might use i18n

  # Annotate rendered view with file names.
  # Remove or comment out as you have no views in an API-only app.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  # Keep this as it relates to Action Controller callbacks, which you are using.
  config.action_controller.raise_on_missing_callback_actions = true

  # You might also want to remove or comment out configurations related to:
  # config.active_record... (if ActiveRecord is not loaded)
  # config.active_job... (if ActiveJob is not loaded)
  # config.action_cable... (if ActionCable is not loaded)
  # config.assets... (if Asset Pipeline is disabled)
  # Ensure these were already removed based on our previous discussions.
end
