require 'net/http'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'aws/ses'
require 'colorize'

@config = OpenStruct.new(YAML.load_file('config.yml').deep_symbolize_keys)
@ses = AWS::SES::Base.new(@config.ses)
@monitors = @config.monitors

puts "Initialized. #{@monitors.count} monitors pending."

def test(url)
  begin
    res = Net::HTTP.get_response(URI(url))

    unless res.is_a? Net::HTTPSuccess
      check_res = Net::HTTP.get_response(URI('https://www.google.com/'))
      if check_res.is_a? Net::HTTPSuccess
        return [res.is_a?(Net::HTTPSuccess), res.code]
      else
        return [true, '-99 (client fail)']
      end
    end

    [res.is_a?(Net::HTTPSuccess), res.code]
  rescue
    [false, '-53 (client fail)']
  end
end

def send_notification(address, type)
  begin
    if address.is_a? String
      @ses.send_email(to: address, source: @config.from, subject: type)
    elsif address.is_a? Array
      address.each do |a|
        @ses.send_email(to: address, source: @config.from, subject: type)
      end
    end
    true
  rescue
    false
  end
end

threads = @monitors.map do |monitor|
  monitor = OpenStruct.new(monitor)

  Thread.new do
    failures = 0
    successes = 0
    currently_up = true

    up = 'UP'.green
    down = 'DOWN'.red

    while true do
      result, code = test(monitor.test_url)

      if currently_up && result
        puts "#{monitor.name}: currently #{up}, tested #{up} (#{code}) 💤 #{monitor.frequency}"
        sleep monitor.frequency
      elsif currently_up && !result
        failures += 1
        puts "#{monitor.name}: currently #{up}, tested #{down} #{failures}/#{monitor.failure_count} (#{code}) 💤 #{monitor.failed_retest}"
        if failures >= monitor.failure_count
          if send_notification(monitor.notification_address, 'DOWN')
            currently_up = false
            successes = 0
            puts "#{' ' * monitor.name.length}: #{down} notification sent, status set to #{down}"
          else
            puts "#{' ' * monitor.name.length}: failed to send notification, will retry next round"
          end
        end
        sleep monitor.failed_retest
      elsif !currently_up && result
        successes += 1
        if successes >= monitor.success_count
          puts "#{monitor.name}: currently #{down}, tested #{up} #{successes}/#{monitor.success_count} (#{code}) 💤 #{monitor.frequency}"
          if send_notification(monitor.notification_address, 'UP')
            currently_up = true
            failures = 0
            puts "#{' ' * monitor.name.length}: #{up} notification sent, status set to #{up}"
          else
            puts "#{' ' * monitor.name.length}: failed to send notification, will retry next round"
          end
          sleep monitor.frequency
        else
          puts "#{monitor.name}: currently #{down}, tested #{up} #{successes}/#{monitor.success_count} (#{code}) 💤 #{monitor.failed_retest}"
          sleep monitor.failed_retest
        end
      elsif !currently_up && !result
        puts "#{monitor.name}: currently #{down}, tested #{down} (#{code}) 💤 #{monitor.frequency}"
        successes = 0
        sleep monitor.failed_retest
      end
    end
  end
end

threads.map(&:join)
