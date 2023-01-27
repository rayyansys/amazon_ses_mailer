# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov.start :rails do
  if ENV['CI']
    SimpleCov::Formatter::LcovFormatter.config do |config|
      config.report_with_single_file = true
      config.single_report_path = 'coverage/lcov.info'
    end

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
      SimpleCov::Formatter::LcovFormatter
    ]
  else
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
      SimpleCov::Formatter::HTMLFormatter
    ]
  end
end
require 'amazon_ses_mailer'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
