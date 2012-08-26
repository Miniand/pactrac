require 'spec_helper'
require 'pactrac/carrier'

describe PacTrac::Carrier do
  it 'should give a list of carriers' do
    PacTrac::Carrier.all.should be_an_instance_of(Array)
  end

  it 'should give a carrier for a known good tracking number' do
    err, carrier = PacTrac::Carrier.for_tracking_number('7414496342')
    err.should be_valid
    carrier.should_not be_nil
  end

  it 'should give an error for a bad tracking number' do
    err, carrier = PacTrac::Carrier.for_tracking_number('&')
    err.should_not be_valid
  end
end
