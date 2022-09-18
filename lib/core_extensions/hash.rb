module CoreExtensions
  module Hash
    def transform_values
      return enum_for(:transform_values) { size } unless block_given?
      return {} if empty?
      result = self.class.new
      each do |key, value|
        result[key] = yield(value)
      end
      result
    end
  end
end

Hash.include CoreExtensions::Hash
