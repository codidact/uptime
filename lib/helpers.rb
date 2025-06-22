require 'date'
require 'net/http'

module Uptime
  module Helpers
    def test(url)
      begin
        res = get(url)
    
        unless res.is_a? Net::HTTPSuccess
          check_res = get('https://www.google.com/')
          if check_res.is_a? Net::HTTPSuccess
            return [res.is_a?(Net::HTTPSuccess), res.code]
          else
            return [true, "#{res.code} (client fail)"]
          end
        end
    
        [res.is_a?(Net::HTTPSuccess), res.code]
      rescue => ex
        @logger.error "#{ex.class}: #{ex.message}"
        ex.backtrace.each do |line|
          @logger.debug line
        end
        [false, "#{ex.class} (client fail)"]
      end
    end

    def get(url)
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                      read_timeout: @net_config[:read_timeout] || 60,
                      open_timeout: @net_config[:open_timeout] || 60) do |http|
        request = Net::HTTP::Get.new uri
        http.request request
      end
    end
  end
end
