require 'net/http'
require 'uri'
require 'json'
require 'timeout'

module SendLayer
  class Client
    BASE_URL = 'https://console.sendlayer.com/api/v1/'
    
    attr_reader :api_key, :base_url, :timeout, :attachment_url_timeout

    def initialize(api_key, options = {})
      @api_key = api_key
      @base_url = options[:base_url] || BASE_URL
      @timeout = options[:timeout] || 30
      @attachment_url_timeout = options[:attachment_url_timeout] || 30000
    end

    def make_request(method, endpoint, data = nil, params = {})
      uri = URI("#{@base_url}#{endpoint}")
      
      # Add query parameters
      unless params.empty?
        uri.query = URI.encode_www_form(params)
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout

      case method.upcase
      when 'GET'
        request = Net::HTTP::Get.new(uri)
      when 'POST'
        request = Net::HTTP::Post.new(uri)
        request.body = data.to_json if data
        request['Content-Type'] = 'application/json'
      when 'DELETE'
        request = Net::HTTP::Delete.new(uri)
      else
        raise SendLayerError.new("Unsupported HTTP method: #{method}")
      end

      request['Authorization'] = "Bearer #{@api_key}"
      request['User-Agent'] = "SendLayer-Ruby/#{::SendLayer::VERSION}"

      begin
        response = http.request(request)
        handle_response(response)
      rescue Timeout::Error
        raise SendLayerError.new("Request timeout after #{@timeout} seconds")
      rescue => e
        raise SendLayerError.new("Network error: #{e.message}")
      end
    end

    private

    def handle_response(response)
      case response.code.to_i
      when 200..299
        return JSON.parse(response.body) if response.body && !response.body.empty?
        return {}
      when 401
        raise SendLayerAuthenticationError.new("Invalid API key")
      when 400
        error_data = parse_error_response(response)
        raise SendLayerValidationError.new(error_data['Error'] || 'Invalid request parameters')
      when 404
        error_data = parse_error_response(response)
        raise SendLayerNotFoundError.new(error_data['Error'] || 'Resource not found')
      when 422
        error_data = parse_error_response(response)
        raise SendLayerValidationError.new(error_data['Error'] || 'Validation failed')
      when 429
        error_data = parse_error_response(response)
        raise SendLayerRateLimitError.new(error_data['Error'] || 'Rate limit exceeded')
      when 500..599
        error_data = parse_error_response(response)
        raise SendLayerInternalServerError.new(error_data['Error'] || 'Internal server error')
      else
        error_data = parse_error_response(response)
        raise SendLayerAPIError.new(
          error_data['Error'] || "HTTP #{response.code} error",
          response.code.to_i,
          response.body
        )
      end
    end

    def parse_error_response(response)
      return {} unless response.body
      JSON.parse(response.body)
    rescue JSON::ParserError
      { 'Error' => response.body }
    end
  end
end
