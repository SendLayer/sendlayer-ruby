require_relative 'sendlayer/version'
require_relative 'sendlayer/client'
require_relative 'sendlayer/emails'
require_relative 'sendlayer/webhooks'
require_relative 'sendlayer/events'
require_relative 'sendlayer/exceptions'

module SendLayer
  class SendLayer
    attr_reader :emails, :webhooks, :events

    def initialize(api_key, options = {})
      @client = Client.new(api_key, options)
      @emails = Emails.new(@client)
      @webhooks = Webhooks.new(@client)
      @events = Events.new(@client)
    end
  end
end
