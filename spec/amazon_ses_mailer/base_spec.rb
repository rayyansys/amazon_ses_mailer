# frozen_string_literal: true

RSpec.describe AmazonSesMailer::Base do
    let(:template_name) { 'welcome_email' }
    let(:options) { { template: template_name } }
    let(:delivery_method) { nil }
    subject { described_class.new(template_name) }
  
    describe '.mail' do
      before do
        allow(AmazonSesMailer::Base).to receive(:delivery_method)
          .and_return(delivery_method)
      end
  
      it 'creates a new message' do
        expect(AmazonSesMailer::Message).to receive(:new)
        subject.mail(options)
      end
    end
  
    describe '.deliveries' do
      context 'when there are no deliveries' do
        it 'should return empty array' do
          expect(AmazonSesMailer::Base.deliveries).to eq([])
        end
      end
  
      context 'when there are deliveries' do
        let(:delivery_method) { :test }
        before do
          allow(AmazonSesMailer::Base).to receive(:delivery_method)
            .and_return(delivery_method)
        end
        it {
          expect { AmazonSesMailer::Base.mail(options).deliver }
            .to change { AmazonSesMailer::Base.deliveries.count }.by(1)
        }
      end
    end
    describe '.transform_array' do
      context 'when given object is array' do
        it 'should convert false/nil into empty string and all others into string' do
          arr = [{ a: 1 }, false]
          expect(AmazonSesMailer::Base.transform_array(arr)).to eq([{ a: '1' }, ''])
        end
      end
  
      context 'when given object is not array' do
        it 'should not convert false/nil into empty string and all others into string' do
          arr = { a: 1, b: false }
          expect(AmazonSesMailer::Base.transform_array(arr)).not_to eq([{ a: '1' }, ''])
        end
      end
    end
    describe '.register_interceptor' do
      context 'when there are interceptors to block certain email deliveries' do
        class MyInterceptor
          def self.delivering_email(message)
            message[:destination][:to_addresses].any? do |email|
              email.include?('@example.com')
            end
          end
        end
  
        it 'should register those interceptors' do
          expect(AmazonSesMailer::Base.register_interceptor(MyInterceptor)).to eq([MyInterceptor])
        end
      end
  
      context 'when there are is no delivering_mail to respond' do
        class FalseInterceptor
        end
        it 'should raise error' do
          expect { AmazonSesMailer::Base.register_interceptor(FalseInterceptor) }.to raise_error
        end
      end
    end
  end
  