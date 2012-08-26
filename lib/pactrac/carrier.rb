require 'pactrac/carrier/dhl'
require 'pactrac/carrier/ems'
require 'pactrac/err'

module PacTrac
  module Carrier
    module_function

    def all
      [Carrier::Dhl, Carrier::Ems]
    end

    def for_tracking_number(tracking_number)
      all.each do |c|
        return Err.new(true), c if c.tracking_number_relevant?(tracking_number)
      end
      return Err.new(false, 'unable to match tracking number to carrier')
    end
  end
end
