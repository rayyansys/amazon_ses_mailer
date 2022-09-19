RSpec.describe CoreExtensions::Hash do
  describe '#transform_values' do
    it 'transforms hash values' do
      original = { a: 'a', b: 'b' }
      mapped = original.transform_values { |val| "#{val}!" }

      expect(mapped[:a]).to eq 'a!'
    end
  end
end
