require 'kabayaki/service_log/factory'

module Kabayaki
  module ServiceLog
    # warmup middleware
    # do not insert middleware before this
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(request, _call)
        Factory.create(server: @app.receiver, action: @app.name).wrap_in_logger { @app.call(request, _call) }
      end
    end
  end
end
