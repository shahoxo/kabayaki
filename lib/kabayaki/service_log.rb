module Kabayaki
  module ServiceLog
    autoload :Factory, 'kabayaki/service_log/factory'
    autoload :Base, 'kabayaki/service_log/base'
    autoload :NullLogger, 'kabayaki/service_log/null_logger'
    autoload :Middleware, 'kabayaki/service_log/middleware'
  end
end
