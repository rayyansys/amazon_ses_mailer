require "bundler/setup"
require "amazon_ses_mailer"
require 'aws-sdk-sesv2'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # When you enable response stubbing, the client will generate fake responses and will not make any HTTP requests.
  # As mentioned in this document https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ClientStubs.html
  config.before do
    Aws.config.update(stub_responses: true)
  end

end
