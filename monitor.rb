require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'io/console'
require 'colorize'
require 'aws/ses'
require_relative 'lib/helpers'
require_relative 'lib/monitor'

include Uptime::Helpers

$stdout.sync = true

@config = OpenStruct.new(YAML.load_file('config.yml').deep_symbolize_keys)
@ses = AWS::SES::Base.new(@config.ses)
@monitors = @config.monitors.map { |m| Uptime::Monitor.new(m, @ses) }

log "Initialized. #{@monitors.count} monitors pending."

threads = @monitors.map do |m|
  m.monitor
end

threads.map(&:join)
