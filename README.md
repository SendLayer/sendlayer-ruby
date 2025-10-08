<a href="https://sendlayer.com">
<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-dark.svg">
  <source media="(prefers-color-scheme: dark)" srcset="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-light.svg">
  <img alt="SendLayer Logo" width="200px" src="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-light.svg">
</picture>
</a>

### SendLayer Ruby SDK

The official Ruby SDK for interacting with the SendLayer API, providing a simple and intuitive interface for sending emails, managing webhooks, and retrieving email events.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sendlayer'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install sendlayer
```

## Quick Start

```ruby
require 'sendlayer'

# Initialize the SDK
sendlayer = SendLayer::SendLayer.new('your-api-key')

# Send an email
response = sendlayer.emails.send(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Test Email',
  text: 'This is a test email'
)

puts "Email sent! Message ID: #{response['MessageID']}"
```

## Features

- **Email Module**: Send emails with HTML/text content, attachments, CC/BCC, reply-to, custom headers, and tags
- **Webhooks Module**: Create, retrieve, and delete webhooks for various email events
- **Events Module**: Retrieve email events with filtering options
- **Error Handling**: Clear, typed errors for API and validation issues

## Email

Send emails using the `SendLayer` client:

```ruby
require 'sendlayer'

sendlayer = SendLayer::SendLayer.new('your-api-key')

# Simple email
response = sendlayer.emails.send(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Welcome!',
  text: 'Welcome to our platform!'
)

# HTML email with sender name
response = sendlayer.emails.send(
  from: { email: 'sender@example.com', name: 'Paulie Paloma' },
  to: 'recipient@example.com',
  subject: 'Welcome!',
  html: '<h1>Welcome!</h1><p>Welcome to our platform!</p>'
)

# Complex email with multiple recipients and attachments
response = sendlayer.emails.send(
  from: { email: 'sender@example.com', name: 'Sender' },
  to: [
    { email: 'recipient1@example.com', name: 'Recipient 1' },
    { email: 'recipient2@example.com', name: 'Recipient 2' }
  ],
  subject: 'Complex Email',
  text: 'Plain text fallback',
  html: '<p>This is a <strong>test email</strong>!</p>',
  cc: [{ email: 'cc@example.com', name: 'CC' }],
  bcc: [{ email: 'bcc@example.com', name: 'BCC' }],
  reply_to: [{ email: 'reply@example.com', name: 'Reply' }],
  attachments: [
    { path: 'path/to/file.pdf', type: 'application/pdf' }
  ],
  headers: { 'X-Custom-Header' => 'value' },
  tags: ['tag1', 'tag2']
)
```

## Events

```ruby
require 'sendlayer'
require 'time'

sendlayer = SendLayer::SendLayer.new('your-api-key')

# Get all events
all_events = sendlayer.events.get
puts "Total events: #{all_events['TotalRecords']}"

# Get filtered events (last 24 hours, opened)
end_time = Time.now
start_time = end_time - (24 * 60 * 60) # 24 hours ago

filtered_events = sendlayer.events.get(
  start_date: start_time,
  end_date: end_time,
  event: 'opened'
)

puts "Filtered events: #{filtered_events['TotalRecords']}"
```

## Webhooks

```ruby
require 'sendlayer'

sendlayer = SendLayer::SendLayer.new('your-api-key')

# Create a webhook
webhook = sendlayer.webhooks.create(
  url: 'https://your-domain.com/webhook',
  event: 'open'
)
puts "Webhook created: #{webhook['WebhookID']}"

# Get all webhooks
webhooks = sendlayer.webhooks.get
puts "Webhooks: #{webhooks}"

# Delete a webhook
sendlayer.webhooks.delete(123)
```

## Error Handling

The SDK provides specific exception types for different error scenarios:

```ruby
require 'sendlayer'

begin
  response = sendlayer.emails.send(
    from: 'sender@example.com',
    to: 'recipient@example.com',
    subject: 'Test Email',
    text: 'This is a test email'
  )
rescue SendLayer::SendLayerAPIError => e
  puts "API error: #{e.message} (Status: #{e.status_code})"
rescue SendLayer::SendLayerValidationError => e
  puts "Validation error: #{e.message}"
rescue SendLayer::SendLayerAuthenticationError => e
  puts "Authentication error: #{e.message}"
rescue SendLayer::SendLayerError => e
  puts "SendLayer error: #{e.message}"
rescue => e
  puts "Unexpected error: #{e.message}"
end
```

## Exception Types

- `SendLayer::SendLayerError`: Base exception for all SendLayer errors
- `SendLayer::SendLayerAPIError`: API-specific errors with status code and response data
- `SendLayer::SendLayerAuthenticationError`: Invalid API key or authentication issues
- `SendLayer::SendLayerValidationError`: Invalid parameters or validation errors
- `SendLayer::SendLayerNotFoundError`: Resource not found (404 errors)
- `SendLayer::SendLayerRateLimitError`: Rate limit exceeded (429 errors)
- `SendLayer::SendLayerInternalServerError`: Server errors (5xx errors)

## Supported Events

### Webhook Events
- `bounce`: Email bounced
- `click`: Link was clicked
- `open`: Email was opened
- `unsubscribe`: User unsubscribed
- `complaint`: User marked as spam
- `delivery`: Email was delivered

### Event Tracking Events
- `accepted`: Email was accepted by the server
- `rejected`: Email was rejected
- `delivered`: Email was delivered
- `opened`: Email was opened
- `clicked`: Link was clicked
- `unsubscribed`: User unsubscribed
- `complained`: User marked as spam
- `failed`: Email delivery failed

## Requirements

- Ruby 2.7.0 or higher
- mime-types gem

## More Details

To learn more about using the SendLayer SDK, be sure to check our [Developer Documentation](https://developers.sendlayer.com/sdks/ruby).

## License

MIT License - see [LICENSE](./LICENSE) file for details
