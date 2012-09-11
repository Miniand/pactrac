require 'nokogiri'
require 'pactrac/err'
require 'pactrac/response'
require 'pactrac/http'
require 'pactrac/http/session'
require 'net/http'
require 'date'

module PacTrac
  module Carrier
    module Dhl
      module_function

      def title
        'DHL'
      end

      def tracking_number_relevant?(tracking_number)
        tracking_number.strip.match(/^\d{10}$/)
      end

      def tracking_request(tracking_number, session)
        err, raw = Http.request(Net::HTTP::Get.new(
          "/content/g0/en/express/tracking.shtml" +
          "?brand=DHL&AWB=#{tracking_number}%0D%0A", 'User-Agent' =>
            'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.1 (KHTML, like' +
            ' Gecko) Chrome/21.0.1180.75 Safari/537.1'), session)
        unless err.valid
          return Err.new(false,
            "there was a problem connecting to the DHL server, #{err.msg}")
        end
        return Err.new(true), Response.new(raw, false)
      end

      def parse_tracking_data(response)
        doc = Nokogiri::HTML(response.raw.body)
        table = doc.css('.clpt_tracking_results table').first
        if table.nil?
          return Err.new(false, 'unable to find tracking data table')
        end
        tracking_data = { :updates => [] }
        origin_node = table.css('#orginURL4').first
        if origin_node.nil?
          return Err.new(false, 'unable to find origin')
        end
        tracking_data[:origin] = origin_node.content
        destination_node = table.css('#destinationURL4').first
        if destination_node.nil?
          return Err.new(false, 'unable to find destination')
        end
        tracking_data[:destination] = destination_node.content
        current_date = nil
        table.children.each do |section|
          next unless ['thead', 'tbody'].include?(section.name.to_s)
          next if section.attribute('class').to_s == 'tophead'
          section.css('tr').each do |row|
            cells = row.css('td, th')
            first_cell = cells.first
            case
            when first_cell.name == 'th' # Date cell
              if first_cell.content.empty?
                current_date = Date.today
              else
                current_date = Date.parse(first_cell.content)
              end
            when first_cell.attribute('class').to_s != 'emptyRow'
              next if current_date.nil?
              tracking_data[:updates] << {
                :message => cells[1].content.strip,
                :location => cells[2].content.strip,
                :at => DateTime.parse(
                  "#{current_date.to_s}T#{cells[3].content.to_s}"),
              }
            end
          end
        end
        return Err.new(true), tracking_data
      end

      def start_session
        Http::Session.start('www.dhl.com', 80)
      end
    end
  end
end
