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
  # Get all events
  puts "Retrieving all events..."
  all_events = sendlayer.events.get
  puts "✅ Retrieved events successfully!"
  puts "Total events: #{all_events}"

  # Get filtered events (last 7 days)
  puts "\nRetrieving events from the last 7 days..."
  end_time = Time.now
  start_time = end_time - (7 * 24 * 60 * 60) # 7 days ago

  filtered_events = sendlayer.events.get(
    start_date: start_time,
    end_date: end_time
  )
  puts "✅ Retrieved filtered events successfully!"
  puts "Events in last 7 days: #{filtered_events['Events']}"

  # Get specific event type (opened)
  puts "\nRetrieving 'opened' events from the last 24 hours..."
  end_time = Time.now
  start_time = end_time - (24 * 60 * 60) # 24 hours ago

  opened_events = sendlayer.events.get(
    start_date: start_time,
    end_date: end_time,
    event: 'opened'
  )
  puts "✅ Retrieved 'opened' events successfully!"
  puts "Opened events in last 24 hours: #{opened_events['TotalRecords']}"

  # Display some sample events
  if all_events['Events'] && !all_events['Events'].empty?
    puts "\nSample events:"
    all_events['Events'].first(3).each_with_index do |event, index|
      puts "  #{index + 1}. Event: #{event['Event']}, MessageID: #{event['MessageID']}, Timestamp: #{event['Timestamp']}"
    end
  end

rescue SendLayer::SendLayerError => e
  puts "❌ SendLayer Error: #{e.message}"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
end
