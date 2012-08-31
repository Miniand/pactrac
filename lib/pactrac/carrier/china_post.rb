require 'nokogiri'
require 'pactrac/err'
require 'pactrac/response'
require 'pactrac/http'
require 'pactrac/http/session'
require 'pactrac/http/cookie'
require 'pactrac/verify/file'
require 'net/http'
require 'date'

module PacTrac
  module Carrier
    module ChinaPost
      module_function

      def title
        'China Post'
      end

      def tracking_number_relevant?(tracking_number)
        tracking_number.strip.match(/^RA\d+CN$/)
      end

      def tracking_request(tracking_number, session)
        err, raw = Http.request(Net::HTTP::Get.new(
          '/item/trace/itemTrace.jsp',
          'User-Agent' => user_agent), session)
        return err unless err.valid
        # Get validation image
        err, raw = Http.request(Net::HTTP::Get.new('/rand',
          'User-Agent' => user_agent), session)
        unless err.valid
          return Err.new(false,
            "there was a problem connecting to the China Post server, " +
            "#{err.msg}")
        end
        f = Verify::File.create('china_post.jpg', raw.body)
        return Err.new(true), Response.new(raw, true, "file://#{f}")
      end

      def verify(tracking_number, verification, session)
        req = Net::HTTP::Post.new('/item/trace/itemTraceAction.do',
          'User-Agent' => user_agent)
        req.set_form_data({ :itemNo => tracking_number, :rand => verification })
        if session.cookies
          req['Cookie'] = Http::Cookie.to_request_header_value(session.cookies)
        end
        err, raw = Http.request(req, session)
        unless err.valid
          return Err.new(false,
            "there was a problem connecting to the China Post server, " +
            "#{err.msg}")
        end
        return Err.new(true), Response.new(raw, false)
      end

      def parse_tracking_data(response)
        doc = Nokogiri::HTML(response.raw.body)
        table = doc.css('table.txt-main')
        if table.nil?
          return Err.new(false, 'unable to find tracking data table')
        end        
        tracking_data = { :updates => [] }
        first = true
        table.css('tr').each do |row|
          if first
            first = false
            next
          end
          cells = row.css('td')
          next if cells.nil? or cells.length < 6
          tracking_data[:updates] << {
            :at => DateTime.parse(cells[5].text.strip),
            :location => cells[3].text.strip,
            :message => cells[2].text.strip,
          }
        end
        if tracking_data[:updates].empty?
          return Err.new(false, "unable to extract any tracking data")
        end
        return Err.new(true), tracking_data
      end

      def start_session
        Http::Session.start('intmail.183.com.cn', 80)
      end

      def user_agent
        'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.1 (KHTML, like' +
          ' Gecko) Chrome/21.0.1180.75 Safari/537.1'
      end
    end
  end
end
