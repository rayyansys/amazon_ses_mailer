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

    context 'when value is array' do
      let(:values) { { key: [nil, string_value] } }

      it { expect(service.send(:transform_hash, values)).to eq({ key:  ['', string_value] } ) }
    end
  end

  describe '#transform_array' do
    context 'when array element is nil' do
      it { expect(service.send(:transform_array, [nil])).to eq(['']) }
    end

    context 'when array element is hash' do
      let(:values) { [{ key: string_value }] }

      it { expect(service.send(:transform_array, values)).to eq([{ key: string_value }]) }
    end

    context 'when array element is array' do
      let(:values) { [[string_value]] }

      it { expect(service.send(:transform_value, values)).to eq([[string_value]]) }
    end

    context 'when array element is string' do
      it { expect(service.send(:transform_value, [string_value])).to eq([string_value]) }
    end

    context 'when array element is mixed' do
      it { expect(service.send(:transform_value, [nil, { key:  string_value }, [string_value], string_value])).to eq(['', { key:  string_value }, [string_value], string_value]) }
    end
  end

  describe '#transform_value' do
    context 'when value is nil' do
      it { expect(service.send(:transform_value, nil)).to eq('') }
    end

    context 'when value is hash' do
      let(:values) { { key: string_value } }

      it { expect(service.send(:transform_value, values)).to eq({ key: string_value }) }
    end

    context 'when value is array' do
      let(:values) { [string_value] }

      it { expect(service.send(:transform_value, values)).to eq([string_value]) }
    end

    context 'when value is string' do
      it { expect(service.send(:transform_value, string_value)).to eq(string_value) }
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
      context 'without custom instance variables' do
        let(:result) { { template_name: template_name, from_email: Faker::Internet.safe_email } }

        before { allow_any_instance_of(described_class).to receive(:convert_instance_variables_to_merge_vars).and_return(result) }

        it 'should return instance variable values' do
          expect(service.send(:process_merge_vars, nil)).to eq(result.to_json)
        end
      end

      context 'with custom instance variables' do
        let(:result) { { template_name: template_name, from_email: Faker::Internet.safe_email } }

        before { service.instance_variable_set(:@from_email, result[:from_email]) }

        it 'should return instance variable values' do
          expect(service.send(:process_merge_vars, nil)).to eq(result.to_json)
        end
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

    context 'with test delivery method' do
      before do
        AmazonSesMailer::Base.delivery_method = :test
        allow_any_instance_of(AmazonSesMailer::Message).to receive(:delivering?).and_return(true)
      end

      after { AmazonSesMailer::Base.delivery_method = :smtp }

      it "sends an email with delivery_proc" do
        expect { service.send(:mail, options).deliver }.to change { service.class.deliveries.count }.by(1)
      end
    end
  end

  describe '#deliveries' do
    let(:options) { { to: email } }

    before { allow_any_instance_of(AmazonSesMailer::Message).to receive(:delivering?).and_return(true) }

    context 'when AmazonSesMailer::Base delivery_method: test' do
      before { allow(AmazonSesMailer::Base).to receive(:delivery_method).and_return(:test) }

      it { expect { service.send(:mail, options).deliver }.to change { service.class.deliveries.count }.by(1) }
    end

    context 'when AmazonSesMailer::Base delivery_method: not test' do
      before do
        allow(AmazonSesMailer::Base).to receive(:delivery_method).and_return(:smtp)
        service.send(:mail, options).deliver
      end

      it { expect { service.send(:mail, options).deliver }.to change { service.class.deliveries.count }.by(0) }
    end
  end

  describe '#convert_instance_variables_to_merge_vars' do
    before { service.instance_variable_set(:@from_email, email) }

    it 'should return all instance variables with values as hash' do
      expect(service.send(:convert_instance_variables_to_merge_vars).deep_symbolize_keys).to eq({ template_name: template_name, from_email: email })
    end
  end
end
