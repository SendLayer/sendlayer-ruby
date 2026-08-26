module SendLayer
  # Base error for the SendLayer SDK.
  #
  # Every SendLayer error carries the same attributes, so callers can read them
  # without first checking which subclass they rescued:
  #
  # - +status_code+ HTTP status of the response, or nil for local errors
  # - +response+    decoded response body, or {} when unavailable
  # - +errors+      raw SendLayer +Errors+ entries, each with the API's numeric
  #                 +Code+ and +Message+; empty for local errors and for
  #                 responses that aren't in that shape
  class SendLayerError < StandardError
    attr_reader :status_code, :response, :errors

    def initialize(message = '', status_code = nil, response = nil, errors = nil)
      @status_code = status_code
      @response = response.nil? ? {} : response
      @errors = errors.nil? ? [] : errors
      super(message)
    end

    # Numeric SendLayer error codes carried by this error, for branching:
    # <tt>if err.codes.include?(14)</tt>.
    #
    # See https://developers.sendlayer.com/api-reference/error-codes
    def codes
      @errors.filter_map { |entry| entry['Code'] if entry.is_a?(Hash) && entry.key?('Code') }
    end
  end

  # Raised for API errors not covered by a more specific type.
  class SendLayerAPIError < SendLayerError
    def initialize(message, status_code = nil, response = nil, errors = nil)
      # Historical string form keeps the status prefix.
      super("API Error #{status_code}: #{message}", status_code, response, errors)
    end
  end

  class SendLayerAuthenticationError < SendLayerError; end
  class SendLayerValidationError < SendLayerError; end
  class SendLayerNotFoundError < SendLayerError; end
  class SendLayerRateLimitError < SendLayerError; end
  class SendLayerInternalServerError < SendLayerError; end
end
