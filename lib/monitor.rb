require 'json'
require 'net/http'
require_relative 'helpers'

module Uptime
  class Monitor
    include Uptime::Helpers

    attr_accessor :name, :test_url, :frequency, :failed_retest, :failure_count, :success_count, :notifications

    ##
    # Create a new Monitor instance.
    # @param config [Hash<Symbol, String>] The monitor's configuration as parsed from YAML.
    # @return [Monitor]
    def initialize(config, ses)
      [:name, :test_url, :frequency, :failed_retest, :failure_count, :success_count, :notifications].each do |sym|
        send "#{sym}=", config[sym]
      end
      @ses = ses
    end

    ##
    # Start a thread monitoring the endpoint as defined.
    # @return [Thread]
    def monitor
      Thread.new do
        failures = 0
        successes = 0
        currently_up = true
    
        up = 'UP'.green
        down = 'DOWN'.red
    
        while true do
          result, code = test(@test_url)
    
          if currently_up && result
            log "#{@name}: currently #{up}, tested #{up} (#{code}) 💤 #{@frequency}"
            sleep @frequency
          elsif currently_up && !result
            failures += 1
            log "#{@name}: currently #{up}, tested #{down} #{failures}/#{@failure_count} (#{code}) 💤 #{@failed_retest}"
            if failures >= @failure_count
              if send_notifications 'DOWN'
                currently_up = false
                successes = 0
                log "#{@name}: #{down} notification sent, status set to #{down}"
              else
                log "#{@name}: failed to send notification, will retry next round"
              end
            end
            sleep @failed_retest
          elsif !currently_up && result
            successes += 1
            if successes >= @success_count
              log "#{@name}: currently #{down}, tested #{up} #{successes}/#{@success_count} (#{code}) 💤 #{@frequency}"
              if send_notifications 'UP'
                currently_up = true
                failures = 0
                log "#{@name}: #{up} notification sent, status set to #{up}"
              else
                log "#{@name}: failed to send notification, will retry next round"
              end
              sleep @frequency
            else
              log "#{@name}: currently #{down}, tested #{up} #{successes}/#{@success_count} (#{code}) 💤 #{@failed_retest}"
              sleep @failed_retest
            end
          elsif !currently_up && !result
            log "#{@name}: currently #{down}, tested #{down} (#{code}) 💤 #{@failed_retest}"
            successes = 0
            sleep @failed_retest
          end
        end
      end
    end

    private

    def send_notifications(status)
      notifications.all? do |notif|
        case notif[:type]
        when 'email'
          send_email_notification(notif, status)
        when 'discord'
          send_discord_webhook(notif, status)
        else
          log "#{@name}: unrecognized notification type #{notif[:type]}"
        end
      end
    end

    def send_email_notification(notif, status)
      address = notif[:to]
      begin
        if address.is_a? String
          @ses.send_email(to: address, source: notif[:from], subject: status,
                          text_body: subbed_content(notif[:content], status))
        elsif address.is_a? Array
          address.each do |a|
            @ses.send_email(to: address, source: notif[:from], subject: status,
                            text_body: subbed_content(notif[:content], status))
          end
        end
        true
      rescue
        false
      end
    end

    def send_discord_webhook(notif, status)
      uri = URI(notif[:url])
      mentions = notif[:mentions].nil? ? '' : notif[:mentions].map { |m| "<@#{m}>" }.join(' ')
      content = subbed_content(notif[:content], status).gsub('$Mentions', mentions)
      params = { content: content }
      params[:username] = notif[:username] unless notif[:username].nil?
      headers = { 'Content-Type': 'application/json' }
      begin
        response = Net::HTTP.post(uri, params.to_json, headers)
        unless response.is_a? Net::HTTPSuccess
          log "#{@name}: failed to send Discord webhook (fail) #{notif[:url]}"
        end
        response.is_a? Net::HTTPSuccess
      rescue
        log "#{@name}: failed to send Discord webhook (error) #{notif[:url]}"
        false
      end
    end

    def subbed_content(content, status)
      content.gsub('$Component', @name)
             .gsub('$Status', status)
    end
  end
end
