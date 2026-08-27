module SendLayer
  class Webhooks
    VALID_EVENTS = %w[bounce click open unsubscribe complaint delivery].freeze

    def initialize(client)
      @client = client
    end

    def create(url:, event:)
      validate_webhook_params(url, event)

      webhook_data = {
        WebhookURL: url,
        Event: event
      }

      @client.make_request('POST', 'webhooks', webhook_data)
    end

    def get
      @client.make_request('GET', 'webhooks')
    end

    def delete(webhook_id)
      raise SendLayerValidationError.new("Webhook ID is required") if webhook_id.nil?

      unless webhook_id.is_a?(Integer) && webhook_id > 0
        raise SendLayerValidationError.new("Webhook ID must be a positive integer")
      end

      @client.make_request('DELETE', "webhooks/#{webhook_id}")
    end

    private

    def validate_webhook_params(url, event)
      raise SendLayerValidationError.new("URL is required") if url.nil? || url.empty?
      raise SendLayerValidationError.new("Event is required") if event.nil? || event.empty?

      unless VALID_EVENTS.include?(event)
        raise SendLayerValidationError.new("Invalid event: #{event}. Valid event types include: #{VALID_EVENTS.join(', ')}")
      end

      # Basic URL validation
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise SendLayerValidationError.new("Invalid URL: #{url}")
      end
    rescue URI::InvalidURIError
      raise SendLayerValidationError.new("Invalid URL: #{url}")
    end
  end
end
