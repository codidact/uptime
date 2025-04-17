require 'date'
require 'net/http'

module Uptime
  module Helpers
    def now
      DateTime.now.strftime '%Y-%m-%d %H:%M:%S'
    end
    
    def log(text)
      puts "[#{now}] #{text}"
    end

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
  end
end
