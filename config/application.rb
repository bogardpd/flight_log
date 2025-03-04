require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Portfolio
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # From Rails 8 upgrade: `to_time` will always preserve the full timezone
    # rather than offset of the receiver in Rails 8.1. To opt in to the new
    # behavior, set `config.active_support.to_time_preserves_timezone = :zone`.
    config.active_support.to_time_preserves_timezone = :zone

    # Change form field error display.
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| ActionController::Base.helpers.content_tag(:span, html_tag, class: "field_with_errors") }

    # Allow Cross-Origin Resource Sharing (CORS) for JSON API requests.
    config.middleware.use Rack::Cors do
      allow do
        origins '*'

        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

  end
end
