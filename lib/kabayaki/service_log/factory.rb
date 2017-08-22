require 'kabayaki/service_log/null_logger'
require 'active_support/inflector'

module Kabayaki
  module ServiceLog
    module Factory
      mattr_accessor(:loggers) { {} }

      class << self
        def create(server:, action:)
          logger = find_logger(server)
          logger.new(server: server, action: action)
        end

        def register(logger)
          loggers[logger.server] = logger
        end

        def abstract_logger_name
          'ApplicationLogger'
        end

        private

        def find_logger(server_instance)
          server = server_instance.class.name.remove('Server').underscore.to_sym
          loggers[server] || default
        end

        def default
          abstract_logger_name.safe_constantize || NullLogger
        end
      end
    end
  end
end
