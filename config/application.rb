require File.expand_path('../boot', __FILE__)

require 'rails/all'
require "logger"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Grp
  class Application < Rails::Application
    cattr_reader :styles, :style_tags_text, :languages

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    require (Rails.root.join("lib/style_compiler"))
    require (Rails.root.join("lib/language_compiler"))

    startup_logger = Logger.new(STDOUT)
    startup_logger.level = Logger::INFO

    StyleCompiler.use_schema(Rails.root.join("app/assets/styles/styles.rng"))
    Dir.chdir(Rails.root.join("app/assets/styles")) { |cwd|
      (@@styles, messages) = StyleCompiler.compile(Dir.entries(".").find_all { |filename| filename.ends_with?(".xml") })

      messages.each { |msg| startup_logger.info(msg) }
    }

    LanguageCompiler.use_schema(Rails.root.join("app/assets/languages/language2.rng"))
    Dir.chdir(Rails.root.join("app/assets/languages")) { |cwd|
      (@@languages, messages) = LanguageCompiler.compile(Dir.entries(".").find_all { |filename| filename.ends_with?(".lang") })

      messages.each { |msg| startup_logger.info(msg) }
    }
  end
end
