# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kabayaki/version'

Gem::Specification.new do |spec|
  spec.name          = "kabayaki"
  spec.version       = Kabayaki::VERSION
  spec.authors       = ["Jun Sitow"]
  spec.email         = ["jshitou@aiming-inc.com"]

  spec.summary       = %q{gRPC constitution}
  spec.description   = %q{gRPC constitution}
  spec.homepage      = "https://wait.for.release"
  spec.license       = "spike..."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gems.aiming-inc.biz/'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir['README.md', 'lib/**/*']
  spec.bindir        = "bin"
  spec.executables   = %w(kabayaki)
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "activesupport", "~> 5.1"
  spec.add_dependency "activerecord", "~> 5.1"
  spec.add_dependency "dotenv"
  spec.add_dependency "pry"
  spec.add_dependency "grpc", "~> 1.4"
  spec.add_dependency "grpc-tools"
  spec.add_dependency "rake", "~> 12.0"
  spec.add_dependency "i18n"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.6"
end
