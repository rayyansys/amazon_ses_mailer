# frozen_string_literal: true
require 'my_interceptor'

RSpec.describe AmazonSesMailer::Message do
    let(:options) { { template: 'welcome_email', reply_to: 'user@example.com' } }
    let(:delivery_proc) { {template: 'welcome_email'} }
    subject { described_class.new(options,MyInterceptor,delivery_proc) }
    
    describe '.ses_client' do
      it 'should call ses client API' do
        expect(AmazonSesMailer::Message).to receive(:ses_client).and_return(:ses_client)
        subject.ses_client
      end
    end

    describe '.initialize' do
        context 'when params are provided' do
            it 'should create new message object' do
                expect(AmazonSesMailer::Message).to receive(:new)
                subject
            end
        end
    end

    describe '.deliver' do
        context 'when message is deliverable' do
            it 'should call deliver to send email' do
               expect(subject).to receive(:deliver)
               subject.deliver
            end
        end
    end

    describe '.build_message' do
      it 'should build message' do
        allow_any_instance_of(AmazonSesMailer::Message).to receive(:build_message).and_return(subject)
        subject
      end
   end

   
end
