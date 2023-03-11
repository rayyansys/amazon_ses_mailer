RSpec.describe AmazonSesMailer::Base do
  let(:template_name) { Faker::Lorem.paragraph }
  let(:string_value)  { Faker::Name.first_name }
  let(:email)         { Faker::Internet.safe_email }
  let(:service)       { described_class.new(template_name) }

  describe '#transform_hash' do
    context 'when value is nil' do
      let(:values) { { key: nil } }

      it 'should replace nil values with empty string' do
        expect(service.send(:transform_hash, values)).to eq({ key: '' })
      end
    end

    context 'when value is string' do
      let(:values) { { key: string_value } }

      it 'should string values as is' do
        expect(service.send(:transform_hash, values)).to eq({ key: string_value })
      end
    end

    context 'when value is hash' do
      context 'when deep hash value is nil' do
        let(:values) { { key: { deep_key: nil } } }

        it 'should replace nil values with empty string' do
          expect(service.send(:transform_hash, values)).to eq({ key: { deep_key: '' } })
        end
      end

      context 'when deep hash value is string' do
        let(:values) { { key: { deep_key: string_value } } }

        it 'should string values as is' do
          expect(service.send(:transform_hash, values)).to eq({ key: { deep_key: string_value } })
        end
      end

      context 'when deep hash value is array' do
        let(:values) { { key: { deep_key: [nil, string_value] } } }

        it 'replace nil values with empty string and  string values as is' do
          expect(service.send(:transform_hash, values)).to eq({ key: { deep_key: ['', string_value] } })
        end
      end
    end
  end

  describe '#process_merge_vars' do
    context 'when merge_vars not empty' do
      let(:merge_vars) { { first_var: nil, second_var: string_value } }
      let(:result)     { { first_var: '', second_var: string_value }.to_json }

      it 'should return merge vars params as is' do
        expect(service.send(:process_merge_vars, merge_vars)).to eq(result)
      end
    end

    context 'when merge_vars empty' do
      let(:result) { { template_name: template_name }.to_json }

      it 'should return instance variable values' do
        expect(service.send(:process_merge_vars, nil)).to eq(result)
      end
    end
  end

  describe '#register_interceptor' do
    let(:interceptor_class) { double }

    context 'when interceptor_class respond_to? delivering_email' do
      before { allow(interceptor_class).to receive(:delivering_email).and_yield({}) }

      it 'should not throw an error' do
        expect { described_class.register_interceptor(interceptor_class) }.not_to raise_error
      end
    end

    context 'when interceptor_class not respond_to? delivering_email' do
      it 'should throw an error' do
        expect { described_class.register_interceptor(interceptor_class) }.to raise_error("#{interceptor_class} does not respond to :delivering_email")
      end
    end
  end

  describe '#mail' do
    let(:options) { { to: email } }
    let(:message) { service.send(:mail, options) }

    it 'should return an instance of AmazonSesMailer::Message' do
      expect(message.class).to eq(AmazonSesMailer::Message)
    end

    it 'should return message with options' do
      expect(message.message[:destination][:to_addresses]).to         eq([email])
      expect(message.message[:content][:template][:template_name]).to eq(template_name)
      expect(message.message[:content][:template][:template_data]).to eq({ template_name: template_name }.to_json)
    end
  end

  describe '#deliveries' do
    let(:options) { { to: email } }

    before do
      allow(AmazonSesMailer::Base).to receive(:delivery_method).and_return(:test)
      allow_any_instance_of(AmazonSesMailer::Message).to receive(:delivering?).and_return(true)
      service.send(:mail, options).deliver
    end

    it 'should set delivered message info inside deliveries' do
      expect(described_class.deliveries.first[:destination][:to_addresses]).to         eq([email])
      expect(described_class.deliveries.first[:content][:template][:template_name]).to eq(template_name)
      expect(described_class.deliveries.first[:content][:template][:template_data]).to eq({ template_name: template_name }.to_json)
    end
  end
end
