RSpec::Matchers.define :be_valid do
  match(&:valid)

  failure_message_for_should do |o|
    "expected valid result, but got the following error: #{o.msg}"
  end
end
