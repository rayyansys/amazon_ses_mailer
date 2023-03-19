RSpec.describe AmazonSesMailer::Message do
  let(:interceptor)   { double }
  let(:delivery_proc) { nil }
  let(:message)       { described_class.new({}, [interceptor], delivery_proc) }

  context '.ses_client' do
    context 'when AmazonSesMailer::Message is defined' do
      let(:ses_client) { double }

      before { described_class.ses_client = ses_client }

      it 'should set client for all instances as custom ses client' do
        expect(message.ses_client.class).to eq(ses_client.class)
      end
    end

    context 'when AmazonSesMailer::Message not defined' do
      before { described_class.ses_client = nil }

      it 'should set client for all instances as Aws::SESV2::Client' do
        expect(message.ses_client.class).to eq(Aws::SESV2::Client)
      end
    end
  end

  context '.initialize' do
    it 'should fill interceptors' do
      expect(message.instance_variable_get(:@interceptors)).to eq([interceptor])
    end

    context 'delivery_proc' do
      context 'when delivery_proc present' do
        let(:delivery_proc) { double }

        it { expect(message.instance_variable_get(:@delivery_proc)).to eq(delivery_proc) }
      end

      context 'when delivery_proc not present' do
        it { expect(message.instance_variable_get(:@delivery_proc).class).to eq(Proc) }
      end
    end
  end

  context '#deliver' do
    context 'when interceptor not allow delivering_email' do
      before do
        allow(interceptor).to receive(:delivering_email).and_return(false)
        message.deliver
      end

      it 'should not send email using aws ses' do
        expect_any_instance_of(Aws::SESV2::Client).not_to receive(:send_email)
      end
    end

    context 'when interceptor allow delivering_email' do
      let(:ses_client) { instance_double(Aws::SESV2::Client) }

      before do
        described_class.ses_client = nil
        allow(Aws::SESV2::Client).to receive(:new).and_return(ses_client)
        allow(ses_client).to         receive(:send_email).and_return(true)
        allow(interceptor).to        receive(:delivering_email).and_return(true)
        message.deliver
      end

      it 'should send email using aws ses client' do
        expect(ses_client).to have_received(:send_email)
      end
    end
  end

  context '#build_message' do
    let(:options) { { from_name: Faker::Name.name, from_email: Faker::Internet.safe_email, to: Faker::Internet.safe_email, reply_to: Faker::Internet.safe_email, template: Faker::Lorem.paragraph, merge_vars: { template: Faker::Lorem.paragraph }.to_json, configuration_set_name: Faker::Lorem.paragraph } }

    context 'when contact_list_name is empty' do
      it 'should fill info without contact_list_name' do
        expect(message.send(:build_message, options)).to eq({ from_email_address:     "#{options[:from_name]} <#{options[:from_email]}>",
                                                              destination:            {
                                                                to_addresses: [options[:to]]
                                                              },
                                                              reply_to_addresses:     [options[:reply_to]],
                                                              content:                {
                                                                template: {
                                                                  template_name: options[:template],
                                                                  template_data: options[:merge_vars]
                                                                }
                                                              },
                                                              configuration_set_name: options[:configuration_set_name] })
      end
    end

    context 'when contact_list_name not empty' do
      let(:options_with_contact_list_name) { options.merge({ contact_list_name: Faker::Lorem.paragraph, topic_name: Faker::Lorem.paragraph }) }

      it 'should fill info with contact_list_name' do
        expect(message.send(:build_message, options_with_contact_list_name)).to eq({ from_email_address:      "#{options[:from_name]} <#{options[:from_email]}>",
                                                                                     destination:             {
                                                                                       to_addresses: [options[:to]]
                                                                                     },
                                                                                     reply_to_addresses:      [options[:reply_to]],
                                                                                     content:                 {
                                                                                       template: {
                                                                                         template_name: options[:template],
                                                                                         template_data: options[:merge_vars]
                                                                                       }
                                                                                     },
                                                                                     configuration_set_name:  options[:configuration_set_name],
                                                                                     list_management_options: {
                                                                                       contact_list_name: options_with_contact_list_name[:contact_list_name],
                                                                                       topic_name:        options_with_contact_list_name[:topic_name]
                                                                                     } })
      end
    end

    context 'when one of params not sent like: configuration_set_name' do
      let(:options) { { from_name: Faker::Name.name, from_email: Faker::Internet.safe_email, to: Faker::Internet.safe_email, reply_to: Faker::Internet.safe_email, template: Faker::Lorem.paragraph, merge_vars: { template: Faker::Lorem.paragraph }.to_json, configuration_set_name: nil } }

      it 'should fill info without contact_list_name and configuration_set_name' do
        expect(message.send(:build_message, options)).to eq({ from_email_address: "#{options[:from_name]} <#{options[:from_email]}>",
                                                              destination:        {
                                                                to_addresses: [options[:to]]
                                                              },
                                                              reply_to_addresses: [options[:reply_to]],
                                                              content:            {
                                                                template: {
                                                                  template_name: options[:template],
                                                                  template_data: options[:merge_vars]
                                                                }
                                                              } })
      end
    end
  end

  context '#ensure_array' do
    context 'when array_or_string is array' do
      let(:array_or_string) { [Faker::Internet.safe_email] }

      it 'should should return array of string as is' do
        expect(message.send(:ensure_array, array_or_string)).to eq(array_or_string)
      end
    end

    context 'when array_or_string is string' do
      let(:array_or_string) { Faker::Internet.safe_email }

      it 'should should return array of array contains string' do
        expect(message.send(:ensure_array, array_or_string)).to eq([array_or_string])
      end
    end

    context 'when array_or_string not array or string' do
      let(:array_or_string) { nil }

      it 'should should return empty array' do
        expect(message.send(:ensure_array, array_or_string)).to be_empty
      end
    end
  end

  context '#build_list_management_options' do
    context 'when options contains contact_list_name present' do
      let(:options) { { contact_list_name: 'test', topic_name: 'email' } }

      it 'should return contact_list_name hash as { contact_list_name, topic_name }' do
        expect(message.send(:build_list_management_options, options)).to eq({ contact_list_name: options[:contact_list_name], topic_name: options[:topic_name] })
      end
    end

    context 'when options contains contact_list_name is not set' do
      let(:options) { { topic_name: 'email' } }

      it 'should return contact_list_name hash as { contact_list_name, topic_name }' do
        expect(message.send(:build_list_management_options, options)).to be_nil
      end
    end
  end

  context '#delivering?' do
    context 'single interceptor' do
      context 'when interceptor not allow delivering_email' do
        before { allow(interceptor).to receive(:delivering_email).and_return(false) }

        it { expect(message.send(:delivering?, message.message)).to be_falsey }
      end

      context 'when interceptor allow delivering_email' do
        before { allow(interceptor).to receive(:delivering_email).and_return(true) }

        it { expect(message.send(:delivering?, message.message)).to be_truthy }
      end
    end

    context 'multi interceptors' do
      let(:second_interceptor) { double }
      let(:message)            { described_class.new({}, [interceptor, second_interceptor], delivery_proc) }

      context 'when first interceptor not allow delivering_email and second one allow' do
        before do
          allow(interceptor).to receive(:delivering_email).and_return(false)
          allow(second_interceptor).to receive(:delivering_email).and_return(true)
        end

        it { expect(message.send(:delivering?, message.message)).to be_falsey }
      end

      context 'when second interceptor not allow delivering_email and first one allow' do
        before do
          allow(interceptor).to receive(:delivering_email).and_return(true)
          allow(second_interceptor).to receive(:delivering_email).and_return(false)
        end

        it { expect(message.send(:delivering?, message.message)).to be_falsey }
      end

      context 'when all interceptors allow delivering_email' do
        before do
          allow(interceptor).to receive(:delivering_email).and_return(true)
          allow(second_interceptor).to receive(:delivering_email).and_return(true)
        end

        it { expect(message.send(:delivering?, message.message)).to be_truthy }
      end
    end
  end
end
