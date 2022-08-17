module AmazonSesMailer
  class Base
    attr_reader :template_name

    class << self
      attr_accessor :default_options
      protected
      # DSL method for setting defaults
      def default(*args, &block)
        @default_options ||= {}
        @default_options.merge!(args.extract_options!)
      end
    end

    def default_options
      (self.class.default_options || {}).merge({template: @template_name})
    end

    def initialize(template_name)
      @template_name = template_name.to_s
    end

    def self.method_missing(method_name, *args, &block)
      new(method_name).send(method_name, *args, &block)
    end

    def mail(options)
      options = default_options.merge(options)
      Message.new(options)
    end
  end
end
