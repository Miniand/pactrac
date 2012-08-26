require 'timeout'
require 'net/http'

module PacTrac
  module Http
    module_function

    def request(req, session)
      raw = nil
      begin
        Timeout::timeout(10) do
          raw = session.session.request(req)
        end
      rescue Timeout::Error => e
        return Err.new(false, 'tracking request took too long to respond')
      rescue Net::HTTPError => e
        return Err.new(false, 'error making tracking request')
      end
      return Err.new(true), raw
    end
  end
end
