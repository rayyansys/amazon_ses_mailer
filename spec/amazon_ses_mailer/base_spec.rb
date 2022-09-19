RSpec.describe AmazonSesMailer::Base do
  let(:options) { {} }
  let(:template_name) { '' }
  let(:delivery_method) { nil }
  subject { described_class.new(template_name) }

  describe '#mail' do
    before do
      allow(AmazonSesMailer::Base).to receieve(:delivery_method)
        .and_return(delivery_method)
    end

    it 'creates a new message' do
      expect(AmazonSesMailer::Message).to receive(:new)
      subject.mail(options)
    end
  end
end
