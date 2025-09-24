require 'spec_helper'

RSpec.describe SendLayer::Webhooks do
  let(:client) { instance_double(SendLayer::Client) }
  let(:webhooks) { described_class.new(client) }

  describe '#create' do
    context 'with valid parameters' do
      it 'creates a webhook successfully' do
        expected_response = { 'WebhookID' => 123 }
        
        allow(client).to receive(:make_request)
          .with('POST', 'webhooks', hash_including(:WebhookURL, :Event))
          .and_return(expected_response)

        response = webhooks.create(
          url: 'https://example.com/webhook',
          event: 'delivery'
        )

        expect(response).to eq(expected_response)
      end

      it 'creates a webhook with different event types' do
        expected_response = { 'WebhookID' => 123 }
        
        allow(client).to receive(:make_request)
          .with('POST', 'webhooks', hash_including(:WebhookURL, :Event))
          .and_return(expected_response)

        %w[bounce click open unsubscribe complaint delivery].each do |event|
          response = webhooks.create(
            url: 'https://example.com/webhook',
            event: event
          )
          expect(response).to eq(expected_response)
        end
      end
    end

    context 'with invalid parameters' do
      it 'raises validation error for missing URL' do
        expect {
          webhooks.create(url: '', event: 'delivery')
        }.to raise_error(SendLayer::SendLayerValidationError, /URL is required/)
      end

      it 'raises validation error for missing event' do
        expect {
          webhooks.create(url: 'https://example.com/webhook', event: '')
        }.to raise_error(SendLayer::SendLayerValidationError, /Event is required/)
      end

      it 'raises validation error for invalid event' do
        expect {
          webhooks.create(url: 'https://example.com/webhook', event: 'invalid')
        }.to raise_error(SendLayer::SendLayerValidationError, /Invalid event/)
      end

      it 'raises validation error for invalid URL' do
        expect {
          webhooks.create(url: 'not-a-url', event: 'delivery')
        }.to raise_error(SendLayer::SendLayerValidationError, /Invalid URL/)
      end
    end
  end

  describe '#get' do
    it 'retrieves all webhooks' do
      expected_response = [{ 'WebhookID' => 123, 'Url' => 'https://example.com/webhook' }]
      
      allow(client).to receive(:make_request)
        .with('GET', 'webhooks')
        .and_return(expected_response)

      response = webhooks.get

      expect(response).to eq(expected_response)
    end
  end

  describe '#delete' do
    it 'deletes a webhook successfully' do
      allow(client).to receive(:make_request)
        .with('DELETE', 'webhooks/123')
        .and_return({})

      expect { webhooks.delete(123) }.not_to raise_error
    end

    it 'raises validation error for missing webhook ID' do
      expect {
        webhooks.delete(nil)
      }.to raise_error(SendLayer::SendLayerValidationError, /Webhook ID is required/)
    end
  end
end
