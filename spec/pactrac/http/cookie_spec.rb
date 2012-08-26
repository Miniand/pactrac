require 'spec_helper'
require 'pactrac/http/cookie'

def mock_response
  raw = double("raw")
  raw.stub(:get_fields) { [
    "session=al98axx; expires=Fri, 31-Dec-1999 23:58:23",
    "query=rubyscript; expires=Fri, 31-Dec-1999 23:58:23"] }

  response = double("response")
  response.stub(:raw) { raw }
  response
end

describe PacTrac::Http::Cookie do
  it 'should parse cookies correctly from a PacTrac HTTP response object' do
    response = mock_response
    cookies = PacTrac::Http::Cookie.from_response(response)
    cookies['session'].should eq('al98axx')
    cookies['query'].should eq('rubyscript')
  end

  it 'should update existing cookies correctly from a PacTrac response' do
    cookies = {
      'session' => 'berg',
      'testvalue' => 'derg',
    }
    response = mock_response
    cookies = PacTrac::Http::Cookie.update_from_response(response, cookies)
    cookies['session'].should eq('al98axx')
    cookies['query'].should eq('rubyscript')
    cookies['testvalue'].should eq('derg')
  end

  it 'should correctly escape ,;=' do
    cookies = { 'unsafe' => ',;=', ',;=' => 'unsafe' }
    headers = PacTrac::Http::Cookie.to_request_header_value(cookies)
    headers.should match(/unsafe\s*=\s*%2C%3B%3D/)
    headers.should match(/%2C%3B%3D\s*=\s*unsafe/)
  end

  it 'should correctly unescape ,;=' do
    headers = 'unsafe=%2C%3B%3D; %2C%3B%3D=unsafe'
    cookies = PacTrac::Http::Cookie.from_request_header_value(headers)
    cookies['unsafe'].should eq(',;=')
    cookies[',;='].should eq('unsafe')
  end
end