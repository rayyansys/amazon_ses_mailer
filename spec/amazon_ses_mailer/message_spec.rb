  RSpec.describe AmazonSesMailer::Message do
    let(:message_class)       { described_class.new({}, [double], nil) }

  
    describe '#build_message' do
      let(:options) { 
                        { 
                            from_name: 'name',
                            from_email: 'user@example.com',
                            to: 'user@example.com',
                            reply_to: 'user@example.com',
                            template: 'template',
                            merge_vars: { merge_vars: 'merge_vars' }.to_json,
                            configuration_set_name: 'test_config',
                            contact_list_name: 'contact_list_name',
                            topic_name:        nil
                        } 
                    }

  
      context 'all values are exits' do  
        it 'work as expexted' do
          expect(message_class.send(:build_message, options)).to eq({
                                                                from_email_address:      "#{options[:from_name]} <#{options[:from_email]}>",
                                                                destination:{
                                                                                to_addresses: [options[:to]]
                                                                            },
                                                                reply_to_addresses:[options[:reply_to]],
                                                                content:{
                                                                            template: {
                                                                                        template_name: options[:template],
                                                                                        template_data: options[:merge_vars]
                                                                                    }
                                                                        },
                                                                configuration_set_name:  options[:configuration_set_name],
                                                                list_management_options: {
                                                                                contact_list_name: options[:contact_list_name],
                                                                                topic_name:        options[:topic_name]
                                                                            } 
                                                                })
        end
      end
  
      context 'missing value' do  
        it 'return message without missing value' do
          expect(message_class.send(:build_message, options.except!(:configuration_set_name))).to eq({
                                                                                                from_email_address:      "#{options[:from_name]} <#{options[:from_email]}>",
                                                                                                destination:{
                                                                                                                to_addresses: [options[:to]]
                                                                                                            },
                                                                                                reply_to_addresses:[options[:reply_to]],
                                                                                                content:{
                                                                                                            template: {
                                                                                                                        template_name: options[:template],
                                                                                                                        template_data: options[:merge_vars]
                                                                                                                    }
                                                                                                        },
                                                                                                list_management_options: {
                                                                                                                contact_list_name: options[:contact_list_name],
                                                                                                                topic_name:        options[:topic_name]
                                                                                                            } 
                                                                                                })
        end
      end
    end
  
    describe '#ensure_array' do
      context 'array as value' do
  
        it 'return same array' do
          expect(message_class.send(:ensure_array, ['test_string'])).to eq(['test_string'])
        end
      end
  
      context 'when array_or_string is string' do
  
        it 'return array of string' do
          expect(message_class.send(:ensure_array, 'test_string')).to eq(['test_string'])
        end
      end
  
      context 'boolean as value' do
  
        it 'return empty array' do
          expect(message_class.send(:ensure_array, true)).to eq([])
        end
      end
    end
  
    describe '#build_list_management_options' do
        let(:options) { { contact_list_name: 'contact_list_name', topic_name: nil } }
  
        it 'return hash as { contact_list_name, topic_name }' do
            expect(message_class.send(:build_list_management_options, options)).to eq({ contact_list_name: options[:contact_list_name], topic_name: options[:topic_name] })
        end
    end
  end
