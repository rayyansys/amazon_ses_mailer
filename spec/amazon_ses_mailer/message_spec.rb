# frozen_string_literal: true

RSpec.describe AmazonSesMailer::Message do
  let(:template_name) { 'welcome_email' }
  let(:options) { { template: template_name, reply_to: 'saba@gmail.com' } }
  subject { described_class.new(template_name) }
  describe '.ensure_array' do
    context 'when string is given in option' do
      it 'should return a string' do
        AmazonSesMailer::Base.mail(options).deliver
        expect(options[:reply_to]).to eq('saba@gmail.com')
      end
    end

    context 'when array is given in option' do
      options = { template: 'welcome_email', reply_to: ['saba@gmail.com'] }
      it 'should return a array' do
        subject = AmazonSesMailer::Base.mail(options).deliver
        expect(subject).not_to receive(:ensure_array).with(options[:reply_to])
      end
    end
  end
  describe '.build_list_management_options' do
    context 'when build_list_management_option is given' do
      let(:template_name) { 'welcome_email' }
      let(:options) { { template: template_name, reply_to: 'saba@gmail.com', contact_list_name: 'saba' } }
      it 'should set contact list name and topic_name' do
        expect(options[:contact_list_name]).to eq('saba')
        subject = AmazonSesMailer::Base.mail(options).deliver
        expect(subject).not_to receive(:build_list_management_options).with(options[:contact_list_name])
      end
    end
  end
end
