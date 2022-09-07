module AmazonSesMailer
  class Base
    attr_reader :template_name

    class << self
      attr_accessor :default_options
      
      def deliveries
        @@_deliveries ||= []
      end

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
      template_name = [self.name, method_name].join('-')
      new(template_name).send(method_name, *args, &block)
    end

    def mail(options)
      options = default_options.merge(options)
      options[:merge_vars] = process_merge_vars(options[:merge_vars])
      Message.new(options, Proc.new { |result| self.class.deliveries << result })
    end

    private

    def process_merge_vars(merge_vars)
      # if no merge_vars specified, extract from instance variables
      merge_vars = convert_instance_variables_to_merge_vars unless merge_vars
      # converts nil/false values to empty strings, and converts all others to strings
      merge_vars.transform_values{|v| !!v ? v.to_s : ''}.to_json
    end

    def convert_instance_variables_to_merge_vars
      self.instance_variable_names.reduce({}) do |result, variable_name|
        key = variable_name.delete "@"
        value = self.instance_variable_get(variable_name)
        result.merge!(key => value)
      end
    end
  end
end
