require 'spec_helper'

RSpec.describe SendLayer::Events do
  let(:client) { instance_double(SendLayer::Client) }
  let(:events) { described_class.new(client) }

  describe '#get' do
    context 'with no parameters' do
      it 'retrieves all events' do
        expected_response = { 'TotalRecords' => 10, 'Events' => [] }
        
        allow(client).to receive(:make_request)
          .with('GET', 'events', nil, {})
          .and_return(expected_response)

        response = events.get

        expect(response).to eq(expected_response)
      end
    end

    context 'with date filters' do
      it 'retrieves events with date range' do
        expected_response = { 'TotalRecords' => 5, 'Events' => [] }
        start_date = Time.now - 86400 # 1 day ago
        end_date = Time.now
        
        allow(client).to receive(:make_request)
          .with('GET', 'events', nil, hash_including(:StartDate, :EndDate))
          .and_return(expected_response)

        response = events.get(
          start_date: start_date,
          end_date: end_date
        )

        expect(response).to eq(expected_response)
      end

      it 'retrieves events with specific event type' do
        expected_response = { 'TotalRecords' => 3, 'Events' => [] }
        
        allow(client).to receive(:make_request)
          .with('GET', 'events', nil, hash_including(:Event))
          .and_return(expected_response)

        response = events.get(event: 'opened')

        expect(response).to eq(expected_response)
      end

      it 'retrieves events with message ID filter' do
        expected_response = { 'TotalRecords' => 1, 'Events' => [] }
        
        allow(client).to receive(:make_request)
          .with('GET', 'events', nil, hash_including(:MessageID))
          .and_return(expected_response)

        response = events.get(message_id: 'test-message-123')

        expect(response).to eq(expected_response)
      end

      it 'retrieves events with pagination' do
        expected_response = { 'TotalRecords' => 100, 'Events' => [] }
        
        allow(client).to receive(:make_request)
          .with('GET', 'events', nil, hash_including(:StartFrom, :RetrieveCount))
          .and_return(expected_response)

        response = events.get(
          start_from: 10,
          retrieve_count: 20
        )

        expect(response).to eq(expected_response)
      end
    end

    context 'with invalid parameters' do
      it 'raises validation error when end date is before start date' do
        start_date = Time.now
        end_date = Time.now - 86400 # 1 day ago
        
        expect {
          events.get(start_date: start_date, end_date: end_date)
        }.to raise_error(SendLayer::SendLayerValidationError, /End date must be after start date/)
      end

      it 'raises validation error for invalid event type' do
        expect {
          events.get(event: 'invalid_event')
        }.to raise_error(SendLayer::SendLayerValidationError, /Invalid event/)
      end

      it 'raises validation error for invalid retrieve count' do
        expect {
          events.get(retrieve_count: 0)
        }.to raise_error(SendLayer::SendLayerValidationError, /RetrieveCount must be greater than 0/)
      end
    end
  end
end
