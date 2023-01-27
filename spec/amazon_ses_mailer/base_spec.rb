# frozen_string_literal: true

require 'my_interceptor'

RSpec.describe AmazonSesMailer::Base do
  let(:template_name) { 'welcome_email' }
  let(:options) { { template: template_name } }
  let(:delivery_method) { nil }
  subject { described_class.new(template_name) }

  describe '.deliveries' do
    context 'when there is no email delivered' do
      it 'should have zero email deliveries' do
        expect(AmazonSesMailer::Base.deliveries).to eq([])
      end
    end

    context 'when an email is delivered' do
      options = { from: 'user@example.com', to: 'user@example.com' }
      AmazonSesMailer::Base.delivery_method = :test
      it 'should not have zero email deliveries' do
        AmazonSesMailer::Base.mail(options).deliver
        expect(AmazonSesMailer::Base.deliveries).not_to eq([])
      end
    end
  end

  describe '.register_inceptors' do
    context 'when there is interceptor.delivering_email to register interceptor' do
      it 'should register interceptors' do
        expect(AmazonSesMailer::Base.register_interceptor(MyInterceptor)).to eq([MyInterceptor])
      end
    end

    context 'when there is no interceptor.delivering_email method to register incerceptor' do
      before do
        class FalseInterceptor
        end
      end
      it 'should not respond to delivering_email' do
        expect { AmazonSesMailer::Base.register_interceptor(FalseInterceptor) }.to raise_error(RuntimeError)
      end
    end
  end

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
end
