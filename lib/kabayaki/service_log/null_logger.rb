module Kabayaki
  module ServiceLog
    class NullLogger
      def initialize(*args); end

      def wrap_in_logger
        yield
      end
    end
  end
end
