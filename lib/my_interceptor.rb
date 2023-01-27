# frozen_string_literal: true

class MyInterceptor
  def self.delivering_email(message)
    message[:destination][:to_addresses].any? do |email|
      email.include?('@example.com')
    end
  end
end
