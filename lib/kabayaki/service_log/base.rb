require 'active_support/callbacks'
require 'kabayaki/service_log/factory'

module Kabayaki
  module ServiceLog
    class Base
      include ActiveSupport::Callbacks
      delegate :action_white_list, :action_black_list, :server_id, to: :class
      delegate :current_user, to: :server
      attr_reader :server, :action
      attr_accessor :caches
      cattr_reader(:default_callbacks) { [] }
      define_callbacks :wrap_in_logger

      def initialize(server:, action:)
        @server, @action = server, action
        @caches = []
      end

      def wrap_in_logger
        result = run_callbacks(:wrap_in_logger) { yield }
        send_log_by_caches
        result
      end

      def server_name
        server.class.name.underscore.to_sym
      end

      # should not conflict with own server log in the day
      def action_id
        @action_id ||= rand(1..2**63)
      end

      def before; end
      def after; end
      def around
        yield
      end

      def user_specified?
        !!current_user
      end

      def bq_log_time
        "#{log_time.strftime("%Y-%m-%d %H:%M:%S")} #{log_time.formatted_offset(true, 'UTC')}"
      end

      def log_time
        @log_time ||= Time.current
      end

      private

      def target?
        filter_by_whitelist && filter_by_black_list
      end

      def filter_by_whitelist
        return true if action_white_list.empty?
        action_white_list.include?(action)
      end

      def filter_by_black_list
        return true if action_white_list.empty?
        !action_black_list.include?(action)
      end

      def send_log_by_caches
        caches.each{|cache| send_log(table: cache[:table], data: cache[:data])}
      end

      def send_log(table:, data:)
        Kabayaki.logger.info("[User log] table: #{table}, data: #{data.merge(server_id: server_id)}")
        # TODO: forward to bigquery
      end

      class << self
        attr_accessor(:action_white_list) { [] }
        attr_accessor(:action_black_list) { [] }

        def inherited(child)
          return if abstract?(child)

          ServiceLog::Factory.register(child)
          child.set_callback :wrap_in_logger, :before, :before, if: :target?
          child.set_callback :wrap_in_logger, :after, :after, if: :target?
          child.set_callback :wrap_in_logger, :around, :around, if: :target?

          # NOTE: デフォルトでユーザー向けのログを刺しているので、必要ないlog senderではskipすること
          child.add_callbacks(child.default_callbacks)
        end

        def default_callbacks=(_callbacks)
          add_callbacks(*_callbacks)
          @@default_callbacks = _callbacks
        end

        def only(*actions)
          action_white_list += actions
        end

        def except(*actions)
          action_black_list += actions
        end

        def add_callbacks(*callback_names)
          callback_names.each do |callback_name|
            callback = find_callback(callback_name)
            next unless callback

            set_callback :wrap_in_logger, :around, callback if callback.respond_to?(:around)
            set_callback :wrap_in_logger, :before, callback if callback.respond_to?(:before)
            set_callback :wrap_in_logger, :after, callback if callback.respond_to?(:after)
          end
        end

        def server
          name.remove('Logger').underscore.to_sym
        end

        def server_id
          @@server_id ||= `hostname`.strip
        end

        private

        def find_callback(key)
          case key
          when Class
            key.new
          when Symbol
            raise 'TODO: support symbol'
          else
            key
          end
        end

        def abstract?(child)
          child.name == ServiceLog::Factory.abstract_logger_name
        end
      end
    end
  end
end
