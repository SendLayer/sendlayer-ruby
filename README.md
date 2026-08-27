<a href="https://sendlayer.com">
<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-dark.svg">
  <source media="(prefers-color-scheme: dark)" srcset="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-light.svg">
  <img alt="SendLayer Logo" width="200px" src="https://sendlayer.com/wp-content/themes/sendlayer-theme/assets/images/svg/logo-light.svg">
</picture>
</a>

### SendLayer Ruby SDK

The official Ruby SDK for interacting with the SendLayer API, providing a simple and intuitive interface for sending emails, managing webhooks, and retrieving email events.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE) [![Publish Ruby Gem](https://github.com/SendLayer/sendlayer-ruby/actions/workflows/publish.yml/badge.svg)](https://github.com/SendLayer/sendlayer-ruby/actions/workflows/publish.yml)

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

# HTML with a plain-text fallback -- supply both and both parts are sent.
# ContentType is reported as HTML, and clients that cannot render HTML fall
# back to the plain-text part.
response = sendlayer.emails.send(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Welcome!',
  html: '<h1>Welcome!</h1><p>Welcome to our platform!</p>',
  text: 'Welcome! Welcome to our platform!'
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

Every SendLayer exception carries the same attributes, so you can read them
without first checking which subclass you rescued:

| Attribute | Description |
|---|---|
| `message` | Human-readable message, taken from the API's own error text when available |
| `status_code` | HTTP status of the response, or `nil` for local errors (timeouts, connection failures, validation) |
| `response` | Decoded response body, or `{}` when unavailable |
| `errors` | Raw SendLayer `Errors` entries, each with the API's numeric `Code` and `Message`; empty for local errors |
| `codes` | Just the numeric codes from `errors`, for branching |

```ruby
require 'sendlayer'

begin
  response = sendlayer.emails.send(
    from: 'sender@example.com',
    to: 'recipient@example.com',
    subject: 'Test Email',
    text: 'This is a test email'
  )
rescue SendLayer::SendLayerAuthenticationError => e
  puts "Check your API key: #{e.message}"
rescue SendLayer::SendLayerValidationError => e
  puts "Validation error: #{e.message}"
rescue SendLayer::SendLayerRateLimitError => e
  puts "Slow down: #{e.message}"
rescue SendLayer::SendLayerError => e
  # Base type -- also catches timeouts, connection errors and any API error
  # without a more specific type.
  puts "SendLayer error: #{e.message} (status: #{e.status_code.inspect})"
  puts "Codes: #{e.codes.inspect}"
end
```

Branch on SendLayer's numeric error codes with `codes`:

```ruby
rescue SendLayer::SendLayerError => e
  puts 'That sender domain is not authorised.' if e.codes.include?(14)
end
```

See the [error code reference](https://developers.sendlayer.com/api-reference/error-codes)
for the full list.

## Exception Types

| Exception | Raised for |
|---|---|
| `SendLayer::SendLayerError` | Base type for everything below, and for local errors: timeouts, connection failures and undecodable responses |
| `SendLayer::SendLayerValidationError` | Invalid parameters (raised locally), and HTTP 400 / 422 |
| `SendLayer::SendLayerAuthenticationError` | HTTP 401 -- invalid API key |
| `SendLayer::SendLayerNotFoundError` | HTTP 404 |
| `SendLayer::SendLayerRateLimitError` | HTTP 429 |
| `SendLayer::SendLayerInternalServerError` | HTTP 500 |
| `SendLayer::SendLayerAPIError` | Any other error status, including 5xx other than 500 |

`SendLayerAPIError` is the only type whose `message` is prefixed -- it reads
`API Error <status>: <message>`. Every other type carries the API's message
unchanged.

Requests time out after 30 seconds by default and raise `SendLayerError`. A
`Net::HTTP` exception is never surfaced to the caller.

## Configuration

Pass an options hash as the second argument:

```ruby
sendlayer = SendLayer::SendLayer.new('your-api-key', {
  timeout: 60,                      # seconds to wait for the API (default 30)
  attachment_url_timeout: 45_000,   # ms to wait when fetching a remote attachment (default 30000)
  headers: { 'X-Request-Id' => 'abc123' } # extra headers sent with every request
})
```

| Option | Default | Description |
|---|---|---|
| `:timeout` | `30` | Seconds to wait for the API before raising `SendLayerError` |
| `:attachment_url_timeout` | `30000` | Milliseconds to wait when downloading an attachment from a URL |
| `:headers` | `{}` | Extra request headers. Cannot override `Authorization` |
| `:base_url` | SendLayer API v1 | Override the API base URL |

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
