require 'thor'
require 'pry'
require 'kabayaki'
require 'kabayaki/application'
require 'logger'

module Kabayaki
  module Logger
    attr_writer :logger

    def logger
      @_logger ||= begin
        _logger = ::Logger.new(STDOUT)
        _logger.level = ::Logger::DEBUG
        _logger
      end
    end
  end

  class Command < ::Thor
    def initialize(*)
      super
      require APP_PATH
      GRPC.extend(Kabayaki::Logger)
    end

    desc 'server [--port]', 'run server (default port is 50051)'
    option :port, type: :numeric, aliases: :p, default: 50051
    def server
      rpc_server = GRPC::RpcServer.new
      rpc_server.add_http2_port("0.0.0.0:#{options[:port]}", :this_port_is_insecure) # TODO: TLS対応
      GRPC.logger.info("... running insecurely on #{options[:port]}")
      Kabayaki.application.servers.each { |s| rpc_server.handle(s) }
      rpc_server.run_till_terminated
    end

    desc 'console', 'run console'
    def console
      Pry::Commands.block_command 'reload!', 'Reload application files' do
        output.puts 'Reloading...'
        Kabayaki.application.reload
      end
      GRPC.logger.level = ::Logger::WARN
      Pry.start
    end

    desc 'generate', 'run generation by proto files'
    def generate
      # FIXME: (do not load application files)
      _c = Kabayaki.application.config
      _command = "bundle exec grpc_tools_ruby_protoc -I #{_c.proto_path.to_s} --ruby_out=#{_c.grpc_message_path.to_s} --grpc_out=#{_c.grpc_service_path.to_s} #{_c.proto_path.join('*.proto').to_s}"
      result = `#{_command}`
      if result.present?
        puts result
      else
        puts "Generate message codes to #{_c.grpc_message_path}"
        puts "Generate service codes to #{_c.grpc_service_path}"
      end
    end

    desc 'new', 'generate init application'
    def new
      p 'TODO: implement new command'
    end
  end
end
