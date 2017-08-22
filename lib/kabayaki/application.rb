require 'active_support'
# TODO: active support側でload順が解決したらremove_methodは消す
#       https://github.com/rails/rails/issues/28918
require 'active_support/core_ext/module/remove_method'
require 'active_support/core_ext'
require 'active_support/configurable'
require 'dotenv'
require 'active_record'
require 'kabayaki/middleware_stack'
require 'kabayaki/service_log'
require 'yaml'

module Kabayaki
  class Application
    include ActiveSupport::Configurable
    include ActiveRecord::Tasks

    class << self
      attr_accessor :called_from

      def inherited(base)
        Kabayaki.app_class = base
        base.called_from = begin
          call_stack = caller_locations.map { |l| l.absolute_path || l.path }
          File.dirname(call_stack.detect { |p| p !~ %r[lib/kabayaki] })
        end
      end
    end

    def initialize
      env_file = ".env.#{Kabayaki.env}"
      File.exist?(env_file) ? Dotenv.load(env_file) : Dotenv.load
      config.root = find_root
      config.grpc_message_path = root.join('app/grpc/messages')
      config.grpc_service_path = root.join('app/grpc/services')
      config.grpc_generated_paths = [ config.grpc_message_path, config.grpc_service_path ]
      config.server_path = root.join('app/servers')
      config.app_paths = [
        config.server_path,
        root.join('app/models'),
        root.join('app/observers'),
        root.join('app/translators'),
        root.join('app/loggers'),
        root.join('app/loggers/concern'),
      ]
      config.grpc_generated_paths.each { |dir| $LOAD_PATH.unshift(dir.to_s) unless $LOAD_PATH.include?(dir.to_s) }
      config.eager_load_paths = config.grpc_generated_paths + config.app_paths
      config.proto_path = root.join('proto')
      config.database_config_path = root.join('config/database.yml')
      config.migration_path = root.join('db/migrate')
      config.middleware = Kabayaki::MiddlewareStack.new
      config.middleware.use Kabayaki::ServiceLog::Middleware
      ActiveSupport::Dependencies.autoload_paths = config.eager_load_paths
      config.authentication = proc { raise 'Setup config authentication and return current_user' }
      I18n.load_path += Dir[root.join('config/locales/*.yml')]
    end

    def servers
      Dir[config.server_path.join('**/*.rb')].map do |server_file|
        relative_path = Pathname.new(server_file).relative_path_from(config.server_path)
        relative_path.sub_ext('').to_s.camelize.safe_constantize
      end.compact
    end

    def root
      config.root
    end

    def eager_load!
      config.grpc_generated_paths.each do |load_path|
        Dir[load_path.join('**/*.rb')].each { |file| require file }
      end
      (config.eager_load_paths - config.grpc_generated_paths).each do |load_path|
        matcher = /\A#{Regexp.escape(load_path.to_s)}\/(.*)\.rb\Z/
        Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
          require_dependency file.sub(matcher, '\1')
        end
      end
    end

    def reload
      config.eager_load_paths.each do |path|
        next if path == config.grpc_message_path || path == config.grpc_service_path # TODO: grpc classesをunloadさせる
        Dir[path.join('**/*.rb')].each { |file| load file }
      end
    end

    def setup_database
      database_config = YAML.load(ERB.new(File.read(config.database_config_path)).result)
      ActiveRecord::Base.configurations = database_config
      DatabaseTasks.database_configuration = database_config
      DatabaseTasks.db_dir = 'db'
    end

    private

    # for autoload
    def name
      ''
    end

    def find_root
      root_path = self.class.called_from
      while root_path && File.directory?(root_path) && !File.exist?("#{root_path}/app")
        parent = File.dirname(root_path)
        root_path = parent != root_path && parent
      end

      root = File.exist?("#{root_path}/app") ? root_path : nil
      raise "Could not find root path for #{self}" unless root

      Pathname.new File.realpath root
    end
  end
end
