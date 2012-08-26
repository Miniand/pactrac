PacTrac - International package tracking for Ruby
=================================================

PacTrac is a library which can be used via API and CLI to fetch raw tracking
data.  In the initial alpha, only DHL is supported, but a number of other
methods are in the process of being added.

Installation
============

```bash
gem install pactrac
```

CLI
===

The binary `pactrac` is included with the gem, usable from the command line.

### Basic usage

If not specified, the carrier company is guessed.

```bash
$ pactrac track 1234567890
```

### Specifying carrier

```bash
$ pactrac track 1234567890 --carrier Dhl
```

### Verifying the request

Some shipping carriers, such as EMS, require CAPTCHA style verifications.  The
CLI allows for this by downloading the CAPTCHA image to a temporary directory,
and allowing you to run the command again adding your verification input.

```bash
$ be pactrac track EE123456789CN
EMS requires verification, please view the image at
file:///tmp/pactrac_1345961387_ems.jpg and run pactrac again using the following
command:

pactrac track EE123456789CN --carrier Ems --cookie JSESSIONID\=WrTlQ59KBnfpq1pWp
hgySgYPTSln1p6rrhDd2pSvFyJt2LJGQ9dr\!-1493181672\;\ TS79e94e\=4f22237fc7dc1c7bf7
176dda6b8992a70d84d223c37efee05039bc0060ac0ec5c32dd2e9
--verify YOUR_VERIFICATION_HERE
```

API
===

To include PacTrac, add `require 'pactrac'` to your script.

### Returning error status as part of a pair

A number of functions which expect failure return a pair of values instead of
just one, to avoid returning different types and to avoid exceptions as control
flow.  The first value is an error struct, with offsets `valid` and `msg`.  If
`valid` is true then the function call was successful, if it is false then `msg`
will be populated with an error message.

### Discover a carrier based on a tracking number

```ruby
PacTrac::Carrier.for_tracking_number('EE123456789')
```

Returns a pair of values, the first an Err struct, the second is the
corresponding carrier module.

### Request tracking information

```ruby
require 'pactrac'

carrier = PacTrac::Carrier.for_tracking_number('1234567890')
session = carrier.start_session   # Start an HTTP session, used in requests
err, response = carrier.tracking_request('1234567890', session)
raise 'Error getting tracking information' unless err.valid
raise 'Verification needed' if response.requires_verification
err, tracking_data = carrier.parse_tracking_data(response)
raise 'Error getting response' unless err.valid
puts "Delivery via #{carrier.title} from #{tracking_data[:origin]} to
  #{tracking_data[:destination]}"
# Output updates ordered by latest
tracking_data[:updates].sort_by { |u| u[:at] }.reverse.each do |u|
  puts "Update time #{u[:at]}: package at #{u[:location]} with message
    #{u[:message]}"
end
```

### Sending verification data

If you have made a tracking request and it requires verification, the
`requires_verification` value in the tracking data struct will be true, and the
`verification_image` will be set as a URI for the location of the image.
Usually the image is downloaded to the local filesystem (file://) for checking.

After manually checking the verification image, a second request is made to the
server.  The cookies from the previous request need to be sent to the new
request.

```ruby
require 'pactrac'
require 'pactrac/http/cookie'

carrier = PacTrac::Carrier.for_tracking_number('EE123456789CN')
session = carrier.start_session   # Start an HTTP session, used in requests
err, response = carrier.tracking_request('EE123456789CN', session)
raise "Error getting tracking information, #{err.msg}" unless err.valid
if response.requires_verification
  session.cookies = PacTrac::Http::Cookie.from_response(response)
  err, response = carrier.verify('EE123456789CN', 'JHRPDS', session)
  raise "Error verifying, #{err.msg}" unless err.valid
end
err, tracking_data = carrier.parse_tracking_data(response)
raise "Error getting response, #{err.msg}" unless err.valid
puts "Delivery via #{carrier.title} from #{tracking_data[:origin]} to
  #{tracking_data[:destination]}"
# Output updates ordered by latest
tracking_data[:updates].sort_by { |u| u[:at] }.reverse.each do |u|
  puts "Update time #{u[:at]}: package at #{u[:location]} with message
    #{u[:message]}"
end
```

Supported carriers
==================

*  EMS - PacTrac::Carrier::Ems
*  DHL - PacTrac::Carrier::Dhl

Testing
=======

Automated testing is done through rspec, and can be run from rake using
`rake spec`.

Style
=====

The gem is written in a functional style, avoiding side effects of functions and
aiming to keep them pure.  The gem is also written to avoid returning different
types, so many functions return a pair of values, one for exit status / message,
and the other for the actual return value.
