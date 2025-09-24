#!/usr/bin/env ruby

require 'sendlayer'

# Initialize the SDK
api_key = ENV['SENDLAYER_API_KEY']
unless api_key
  puts "Please set SENDLAYER_API_KEY environment variable"
  exit 1
end

sendlayer = SendLayer::SendLayer.new(api_key)

begin
  # Create a webhook
  puts "Creating a webhook..."
  webhook = sendlayer.webhooks.create(
    url: 'https://example.com/webhook',
    event: 'open'
  )
  puts "✅ Webhook created successfully!"
  puts "Webhook ID: #{webhook}"

  # Get all webhooks
  puts "\nRetrieving all webhooks..."
  webhooks = sendlayer.webhooks.get
  puts "✅ Retrieved #{webhooks.length} webhook(s)"
  webhooks.each_with_index do |webhook, index|
    puts " Webhooks:  #{webhooks}"
  end

  # Delete the webhook we just created
  # if webhook['WebhookID']
  puts "\nDeleting webhook..."
  sendlayer.webhooks.delete(27712)
  puts "✅ Webhook deleted successfully!"
  # end

rescue SendLayer::SendLayerError => e
  puts "❌ SendLayer Error: #{e.message}"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
end
