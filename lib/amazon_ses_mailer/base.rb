module AmazonSesMailer
  class Base
    attr_reader :template_name

    class << self
      attr_accessor :delivery_method
      
      def deliveries
        @@_deliveries ||= []
      end

      def register_interceptor(interceptor_class)
        @@__interceptors ||= []
        unless interceptor_class.respond_to?(:delivering_email)
          raise "#{interceptor_class} does not respond to :delivering_email"
        end
        @@__interceptors << interceptor_class
      end

      protected
      # DSL method for setting defaults
      def default(*args, &block)
        @default_options ||= {}
        @default_options.merge!(args.extract_options!)
      end
    end

    def default_options
      (self.class.instance_variable_get(:@default_options) || {}).merge({template: @template_name})
    end

    def initialize(template_name)
      @template_name = template_name.to_s
      @@__interceptors ||= []
    end

    def self.method_missing(method_name, *args, &block)
      template_name = [self.name, method_name].join('-')
      new(template_name).send(method_name, *args, &block)
    end

    def mail(options)
      options = default_options.merge(options)
      options[:merge_vars] = process_merge_vars(options[:merge_vars])
      delivery_proc = Proc.new { |delivery|
        self.class.deliveries << OpenStruct.new(delivery.merge({template: options[:template]}))
      } if AmazonSesMailer::Base.delivery_method == :test
      Message.new(options, @@__interceptors, delivery_proc)
    end

    private

    def process_merge_vars(merge_vars)
      # if no merge_vars specified, extract from instance variables
      merge_vars = convert_instance_variables_to_merge_vars unless merge_vars
      transform_hash(merge_vars).to_json
    end

    def convert_instance_variables_to_merge_vars
      self.instance_variable_names.reduce({}) do |result, variable_name|
        key = variable_name.delete "@"
        value = self.instance_variable_get(variable_name)
        result.merge!(key => value)
      end
    end

    def transform_hash(hash)
      hash.transform_values{ |value| transform_value(value) }
    end
    
    def transform_array(arr)
      arr.map{|value| transform_value(value)}
    end
    
    def transform_value(value)
      # recurse on hashes/arrays, converts nil/false values to empty strings, and converts all others to strings
      return '' unless !!value
      return transform_hash(value) if value.is_a?(Hash)
      return transform_array(value) if value.is_a?(Array)
      return value.to_s
    end
  end
end
