require "kabayaki/version"
require "active_support/string_inquirer"
require 'grpc'
require 'kabayaki/grpc/monkey_patches'

module Kabayaki
  autoload :Application, 'kabayaki/application'
  autoload :ServiceLog, 'kabayaki/service_log'
  autoload :MiddlewareStack, 'kabayaki/middleware_stack'

  class << self
    attr_accessor :app_class

    def application
      @application ||= app_class.new if app_class
    end

    def root
      application && application.root
    end

    def env
      ActiveSupport::StringInquirer.new(ENV['KABAYAKI_ENV'] || 'development')
    end

    def groups
      [ :default, env ]
    end
  end

  class << self
    def logger
      GRPC.logger
    end

    def logger=(_logger)
      GRPC.logger = _logger
    end
  end
end

GRPC::RpcDesc.prepend Kabayaki::RpcDescMonkeyPatch
GRPC::GenericService::Dsl.include Kabayaki::Authenticatable::Dsl
GRPC::GenericService.include Kabayaki::Authenticatable
