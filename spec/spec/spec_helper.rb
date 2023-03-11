require 'rspec'
require 'active_support'
require 'active_support/core_ext'
require "bundler/setup"
require "amazon_ses_mailer"
require 'aws-sdk-sesv2'
require 'faker'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before do
    Aws.config.update(stub_responses: true)
  end

  AmazonSesMailer::Base.delivery_method == :test
end
