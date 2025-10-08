module SendLayer
  class Events
    VALID_EVENTS = %w[accepted rejected delivered opened clicked unsubscribed complained failed].freeze

    def initialize(client)
      @client = client
    end

    def get(start_date: nil, end_date: nil, event: nil, message_id: nil, start_from: nil, retrieve_count: nil)
      validate_events_params(start_date, end_date, event, retrieve_count)
      
      params = {}
      params[:StartDate] = start_date.to_i if start_date
      params[:EndDate] = end_date.to_i if end_date
      params[:Event] = event if event
      params[:MessageID] = message_id if message_id
      params[:StartFrom] = start_from if start_from
      params[:RetrieveCount] = retrieve_count if retrieve_count

      @client.make_request('GET', 'events', nil, params)
    end

    private

    def validate_events_params(start_date, end_date, event, retrieve_count)
      if start_date && end_date && end_date < start_date
        raise SendLayerValidationError.new("End date must be after start date")
      end

      if event && !VALID_EVENTS.include?(event)
        raise SendLayerValidationError.new("Invalid event: #{event}. Valid events: #{VALID_EVENTS.join(', ')}")
      end

      if retrieve_count && retrieve_count <= 0
        raise SendLayerValidationError.new("RetrieveCount must be greater than 0")
      end
    end
  end
end
