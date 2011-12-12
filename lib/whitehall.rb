module Whitehall
  autoload :Random, 'whitehall/random'
  autoload :RandomKey, 'whitehall/random_key'
  autoload :FormBuilder, 'whitehall/form_builder'
  autoload :QuietAssetLogger, 'whitehall/quiet_asset_logger'
  autoload :Presenters, 'whitehall/presenters'
  autoload :RedirectToRouterPrefix, 'whitehall/redirect_to_router_prefix'
  autoload :RouterPrefixEngine, 'whitehall/router_prefix_engine'

  class << self
    def router_prefix
      "/government"
    end

    def government_single_domain?(request)
      request.headers["HTTP_X_GOVUK_ROUTER_REQUEST"].present?
    end

    def platform
      ENV["FACTER_govuk_platform"] || Rails.env
    end

    def secrets
      @secrets ||= load_secrets
    end

    def aws_access_key_id
      secrets["aws_access_key_id"]
    end

    def aws_secret_access_key
      secrets["aws_secret_access_key"]
    end

    def use_s3?
      !Rails.env.test? && aws_access_key_id && aws_secret_access_key
    end

    private

    def load_secrets
      if File.exists?(secrets_path)
        YAML.load_file(secrets_path)
      else
        {}
      end
    end

    def secrets_path
      Rails.root + 'config' + 'whitehall_secrets.yml'
    end
  end
end