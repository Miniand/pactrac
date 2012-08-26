require 'spec_helper'
require 'pactrac/carrier/dhl'
require 'pactrac/http/session'

describe PacTrac::Carrier::Dhl do
  it 'should have a title' do
    PacTrac::Carrier::Dhl.title.should eq('DHL')
  end

  it 'should be relevant for a known working tracking number' do
    PacTrac::Carrier::Dhl.tracking_number_relevant?('7414496342').should be_true
  end

  it 'should not be relevant for an invalid tracking number' do
    PacTrac::Carrier::Dhl.tracking_number_relevant?('&').should be_false
  end

  it 'should return tracking data for a known working tracking number' do
    session = PacTrac::Carrier::Dhl.start_session
    err, resp = PacTrac::Carrier::Dhl.tracking_request('7414496342', session)
    err.should be_valid
    resp.raw.should_not be_nil
    resp.requires_verification.should be_false
    PacTrac::Http::Session.finish(session)
    err, tracking_data = PacTrac::Carrier::Dhl.parse_tracking_data(resp)
    err.should be_valid
    tracking_data[:origin].should_not be_nil
    tracking_data[:destination].should_not be_nil
    tracking_data[:updates].should_not be_empty
  end
end
