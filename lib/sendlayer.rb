require_relative 'sendlayer/version'
# Loaded before the client: Client::ERROR_MAP resolves these classes at
# class-definition time, so they must already exist.
require_relative 'sendlayer/exceptions'
require_relative 'sendlayer/client'
require_relative 'sendlayer/emails'
require_relative 'sendlayer/webhooks'
require_relative 'sendlayer/events'

module SendLayer
  class SendLayer
    attr_reader :emails, :webhooks, :events

    # Initialize the SDK.
    #
    # @param api_key [String] Your SendLayer API key.
    # @param options [Hash] Optional settings forwarded to the underlying
    #   client: +:timeout+ (seconds, default 30), +:attachment_url_timeout+
    #   (milliseconds), +:headers+ (extra request headers) and +:base_url+.
    def initialize(api_key, options = {})
      @client = Client.new(api_key, options)
      @emails = Emails.new(@client)
      @webhooks = Webhooks.new(@client)
      @events = Events.new(@client)
    end
  end
end
