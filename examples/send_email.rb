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
  # Send a simple email
  puts "Sending a simple email..."
  response = sendlayer.emails.send(
    from: 'paulie@example.com',
    to: 'pattie@example.com',
    subject: 'Ruby SDK Test Email',
    text: 'This is a test email sent using the SendLayer Ruby SDK!'
  )
  puts "✅ Email sent successfully!"
  puts "Message ID: #{response}"

  # Send an HTML email with sender name
  puts "\nSending an HTML email..."
  response = sendlayer.emails.send(
    from: { email: 'paulie@example.com', name: 'Paulie Paloma' },
    to: [
      {name: 'Pattie Paloma', email:'pattie@example.com'},
      {name: 'John Doe', email:'john@example.com'}
    ],
    subject: 'HTML Email Test',
    html: '<h1>Hello from Ruby!</h1><p>This is an <strong>HTML</strong> email sent using the SendLayer Ruby SDK.</p>',
    text: 'Hello from Ruby! This is an HTML email sent using the SendLayer Ruby SDK.',
    attachments: [
      {
        path: './path/to/attachment.pdf',
        type: 'application/pdf'
      },
      { 
        path: 'https://placehold.co/600x400.png',
        type: 'image/png'
      }
    ]
  )
  puts "✅ HTML email sent successfully!"
  puts "Message ID: #{response}"

rescue SendLayer::SendLayerError => e
  puts "❌ SendLayer Error: #{e.message}"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
end
