
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "amazon_ses_mailer/version"

Gem::Specification.new do |spec|
  spec.name          = "amazon_ses_mailer"
  spec.version       = AmazonSesMailer::VERSION
  spec.authors       = ["Hossam Hammady"]
  spec.email         = ["hossam@rayyan.ai"]

  spec.summary       = %q{Send emails from Rails using templates hosted on Amazon SES}
  spec.description   = %q{Send emails from Rails using templates hosted on Amazon SES}
  spec.homepage      = "https://github.com/rayyansys/amazon_ses_mailer"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",       "~> 1.17"
  spec.add_development_dependency "rake",          "~> 10.0"
  spec.add_development_dependency "rspec",         "~> 3.0"
  spec.add_development_dependency "activesupport", "~> 6.0"
  spec.add_development_dependency "faker",         "~> 3.0"

  spec.add_runtime_dependency "aws-sdk-sesv2", "~> 1.0"
end
