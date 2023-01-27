class MyInterceptor
    def self.delivering_email(message)
      message[:destination][:to_addresses].any? { |email|
        email.include?('@example.com')
      }
    end
  end