require 'uri'

module PacTrac
  module Http
    module Cookie
      module_function

      def from_response(response)
        from_raw(response.raw)
      end

      def from_raw(raw)
        cookies = {}
        raw.get_fields('Set-Cookie').each do |c|
          key, value = from_response_header_value(c)
          cookies[key] = value
        end
        cookies
      end

      def from_response_header_value(header_value)
        header_value.split(/\s*;\s*/)[0].split(/\s*=\s*/)[0,2].map {|t|
          URI.unescape(t) }
      end

      def update_from_response(response, cookies)
        update_from_raw(response.raw, cookies)
      end

      def update_from_raw(raw, cookies)
        c = cookies.clone
        from_raw(raw).each do |key, value|
          c[key] = value
        end
        c
      end

      def to_request_header_value(cookies)
        cookies.map { |key, value|
          "#{URI.escape(key, ',;=')}=#{URI.escape(value, ',;=')}"
        }.join('; ')
      end

      def to_request_header(cookies)
        "Cookie: #{to_request_header_value(cookies)}"
      end

      def from_request_header_value(header_value)
        header_value.split(/\s*;\s*/).reject{ |v| v.strip == '' }.map { |p| 
          p.split(/\s*=\s*/)[0,2].map {|t| URI.unescape(t) }
        }.inject({}) { |hash, (key, value)|
          hash[key] = value
          hash
        }
      end
    end
  end
end
