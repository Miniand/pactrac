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
    module Ems
      module_function

      def title
        'EMS'
      end

      def tracking_number_relevant?(tracking_number)
        tracking_number.strip.match(/^EE\d+CN$/)
      end

      def tracking_request(tracking_number, session)
        err, raw = Http.request(Net::HTTP::Get.new('/english.html',
          'User-Agent' => user_agent), session)
        return err unless err.valid
        # Get validation image
        err, raw = Http.request(Net::HTTP::Get.new('/ems/rand',
          'User-Agent' => user_agent), session)
        unless err.valid
          return Err.new(false,
            "there was a problem connecting to the EMS server, #{err.msg}")
        end
        f = Verify::File.create('ems.jpg', raw.body)
        return Err.new(true), Response.new(raw, true, "file://#{f}")
      end

      def verify(tracking_number, verification, session)
        req = Net::HTTP::Post.new('/ems/order/singleQuery_e',
          'User-Agent' => user_agent)
        req.set_form_data({ :mailNum => tracking_number, :checkCode =>
          verification })
        if session.cookies
          req['Cookie'] = Http::Cookie.to_request_header_value(session.cookies)
        end
        err, raw = Http.request(req, session)
        unless err.valid
          return Err.new(false,
            "there was a problem connecting to the EMS server, #{err.msg}")
        end
        if raw.body.match(/failure/i)
          return Err.new(false, 'failure to verify using given code')
        end
        return Err.new(true), Response.new(raw, false)
      end

      def parse_tracking_data(response)
        doc = Nokogiri::HTML(response.raw.body)
        table = doc.css('.mailnum_result_box table')
        if table.nil?
          return Err.new(false, 'unable to find tracking data table')
        end        
        tracking_data = { :updates => [] }
        table.css('tr').each do |row|
          cells = row.css('td')
          next if cells.nil? or cells.length < 2
          tracking_data[:updates] << {
            :at => DateTime.parse(cells[0].content.to_s),
            :location => cells[1].content.to_s.strip,
            :message => cells[2].content.to_s.strip,
          }
        end
        return Err.new(true), tracking_data
      end

      def start_session
        Http::Session.start('www.ems.com.cn', 80)
      end

      def user_agent
        'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.1 (KHTML, like' +
          ' Gecko) Chrome/21.0.1180.75 Safari/537.1'
      end
    end
  end
end
