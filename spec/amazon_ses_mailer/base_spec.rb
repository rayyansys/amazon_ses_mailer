RSpec.describe AmazonSesMailer::Base do
    let(:base_class)       { described_class.new("template sample") }
  
    describe '#register_interceptor' do
        let(:mock_interceptor_class) { double }

        context 'when respond_to? delivering_email' do
            before do
                allow(mock_interceptor_class).to receive(:mock_delivering_email).and_return(true)
            end
        
            it 'error not raised' do
                expect { described_class.register_interceptor(mock_interceptor_class) }.not_to raise_error
            end
          end
        
          context 'when not respond_to? delivering_email' do
            before do
                allow(mock_interceptor_class).to receive(:mock_delivering_email).and_return(false)
            end
        
            it 'error raised' do
                expect { described_class.register_interceptor(mock_interceptor_class) }.to raise_error("#{interceptor_class} does not respond to :delivering_email")
            end
        end
    end


    describe '#mail' do
        let(:options) { { to: "user@example.com" } }

        before do
            # As in read me document i have to add this line to skip deliveries and accumulate messages in a testable array instead:
            AmazonSesMailer::Base.delivery_method = :test

            allow_any_instance_of(AmazonSesMailer::Message).to receive(:delivering?).and_return(true)
        end

        # To test proc call we have to check if the count changed https://github.com/rspec/rspec-expectations/issues/1106#issuecomment-490625682
        it "email sent" do
            expect { base_class.send(:mail, options).deliver }.to change { base_class.class.deliveries.count }.by(1)
        end
    end

    describe '#process_merge_vars' do
        context 'not empty merge_vars' do
            let(:test_varaibale) { { key: nil } }
            let(:result)     { { key: '' }.to_json }

            it 'should return merge vars params as is' do
                expect(base_class.send(:process_merge_vars, merge_vars)).to eq(result)
            end
        end

        context 'empty merge_vars ' do
            before { allow_any_instance_of(described_class).to receive(:convert_instance_variables_to_merge_vars).and_return(true) }

            it 'should return instance variable values' do
                expect(base_class.send(:process_merge_vars, nil)).to eq(true)
            end
        end
    end
  
    describe '#convert_instance_variables_to_merge_vars' do
      before { base_class.instance_variable_set(:key, "test value") }
  
      it 'return hash' do
        expect(base_class.send(:convert_instance_variables_to_merge_vars)).to eq({  key: "test value" })
      end
    end

    describe '#transform_hash' do
        let(:values) { {key: false} }
  
        it 'shoulld transformed to key value to empty string' do
          expect(base_class.send(:transform_hash, values)).to eq({ key: "" })
        end
    end
  
    describe '#transform_array' do
        let(:values) { [false] }
  
        it it 'shoulld transformed to array of empty string' do
            { expect(base_class.send(:transform_value, values)).to eq([""]) }
        end
    end
  
    describe '#transform_value' do
      context 'false as value' do
        it { expect(base_class.send(:transform_value, false)).to eq('') }
      end
  
      context 'hash as value ' do  
        it { expect(base_class.send(:transform_value, { key: "test_value" })).to eq({ key: string_value }) }
      end
  
      context 'array as value' do  
        it { expect(base_class.send(:transform_value, [key: "test_value"])).to eq([string_value]) }
      end
  
      context 'string as value' do
        it { expect(base_class.send(:transform_value, "test_value")).to eq(string_value) }
      end
    end
end
