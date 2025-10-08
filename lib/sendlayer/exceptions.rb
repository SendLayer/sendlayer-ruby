module SendLayer
  class SendLayerError < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
      super(message)
    end
  end

  class SendLayerAPIError < SendLayerError
    attr_reader :status_code, :response

    def initialize(message, status_code = nil, response = nil)
      @status_code = status_code
      @response = response
      super(message)
    end
  end

  class SendLayerAuthenticationError < SendLayerError; end
  class SendLayerValidationError < SendLayerError; end
  class SendLayerNotFoundError < SendLayerError; end
  class SendLayerRateLimitError < SendLayerError; end
  class SendLayerInternalServerError < SendLayerError; end
end
