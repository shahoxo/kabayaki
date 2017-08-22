# grpc monkey patch
module Kabayaki
  module RpcDescMonkeyPatch
    def handle_request_response(active_call, mth)
      req = active_call.remote_read
      app = Kabayaki.application.config.middleware.build(mth)
      resp = app.call(req, active_call.single_req_view)
      active_call.server_unary_response(
        resp, trailing_metadata: active_call.output_metadata)
    end
  end

  module Authenticatable
    module Dsl
      def authenticate_on(*actions)
        mod = Module.new
        actions.each do |action|
          mod.module_eval do
            define_method(action) do |*args, &block|
              authenticate(*args)
              super(*args, &block)
            end
          end
        end
        prepend mod
      end
    end

    def authenticate(request, _call)
      @current_user = nil
      @current_user = Kabayaki.application.config.authentication.call(request, _call)
    end

    def current_user
      @current_user
    end
  end
end
