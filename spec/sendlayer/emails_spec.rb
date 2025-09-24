require 'spec_helper'

RSpec.describe SendLayer::Emails do
  let(:client) { instance_double(SendLayer::Client) }
  let(:emails) { described_class.new(client) }

  describe '#send' do
    context 'with valid parameters' do
      it 'sends an email successfully' do
        expected_response = { 'MessageID' => 'test-123' }
        
        allow(client).to receive(:make_request)
          .with('POST', 'email', hash_including(:From, :To, :Subject))
          .and_return(expected_response)

        response = emails.send(
          from: 'test@example.com',
          to: 'recipient@example.com',
          subject: 'Test',
          text: 'Test content'
        )

        expect(response).to eq(expected_response)
      end

      it 'sends an email with HTML content' do
        expected_response = { 'MessageID' => 'test-123' }
        
        allow(client).to receive(:make_request)
          .with('POST', 'email', hash_including(:From, :To, :Subject, :HTMLContent))
          .and_return(expected_response)

        response = emails.send(
          from: 'test@example.com',
          to: 'recipient@example.com',
          subject: 'Test',
          html: '<p>Test content</p>'
        )

        expect(response).to eq(expected_response)
      end

      it 'sends an email with complex recipient format' do
        expected_response = { 'MessageID' => 'test-123' }
        
        allow(client).to receive(:make_request)
          .with('POST', 'email', hash_including(:From, :To, :Subject))
          .and_return(expected_response)

        response = emails.send(
          from: { email: 'test@example.com', name: 'Test Sender' },
          to: [
            { email: 'recipient1@example.com', name: 'Recipient 1' },
            { email: 'recipient2@example.com', name: 'Recipient 2' }
          ],
          subject: 'Test',
          text: 'Test content'
        )

        expect(response).to eq(expected_response)
      end
    end

    context 'with invalid parameters' do
      it 'raises validation error when no content provided' do
        expect {
          emails.send(
            from: 'test@example.com',
            to: 'recipient@example.com',
            subject: 'Test'
          )
        }.to raise_error(SendLayer::SendLayerValidationError, /Either 'text' or 'html' content must be provided/)
      end

      it 'raises validation error for invalid email' do
        expect {
          emails.send(
            from: 'invalid-email',
            to: 'recipient@example.com',
            subject: 'Test',
            text: 'Test content'
          )
        }.to raise_error(SendLayer::SendLayerValidationError, /Invalid sender email address: invalid-email/)
      end

      it 'raises validation error for invalid recipient format' do
        expect {
          emails.send(
            from: 'test@example.com',
            to: 123, # Invalid format
            subject: 'Test',
            text: 'Test content'
          )
        }.to raise_error(SendLayer::SendLayerValidationError, /Invalid recipients format/)
      end
    end
  end
end
