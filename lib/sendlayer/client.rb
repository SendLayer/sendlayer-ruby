require 'net/http'
require 'uri'
require 'json'
require 'timeout'

require_relative 'version'
require_relative 'exceptions'

module SendLayer
  class Client
    BASE_URL = 'https://console.sendlayer.com/api/v1/'.freeze

    # Seconds to wait for the API before giving up.
    DEFAULT_TIMEOUT = 30

    # HTTP status => [error class, fallback message used when the API response
    # carries no message of its own].
    ERROR_MAP = {
      400 => [SendLayerValidationError,     'Invalid request parameters'],
      401 => [SendLayerAuthenticationError, 'Invalid API key'],
      404 => [SendLayerNotFoundError,       'Resource not found'],
      422 => [SendLayerValidationError,     'Unprocessable Entity'],
      429 => [SendLayerRateLimitError,      'Rate limit exceeded'],
      500 => [SendLayerInternalServerError, 'Internal server error']
    }.freeze

    attr_reader :api_key, :base_url, :timeout, :attachment_url_timeout

    def initialize(api_key, options = {})
      @api_key = api_key
      @base_url = options[:base_url] || BASE_URL
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
      @attachment_url_timeout = options[:attachment_url_timeout] || 30_000
      @headers = options[:headers] || {}
    end

    # Make a request to the SendLayer API.
    #
    # Always returns a Hash/Array or raises a SendLayerError -- a Net::HTTP
    # exception is never surfaced to the caller.
    def make_request(method, endpoint, data = nil, params = {})
      uri = URI("#{@base_url}#{endpoint}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      # Derived from the URI rather than forced on, so an http:// base_url
      # (a local test server, say) is actually usable.
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = @timeout
      # A connection that never completes its handshake would otherwise hang
      # past read_timeout, which only covers waiting for the response body.
      http.open_timeout = @timeout

      request = build_request(method, uri, data)

      # Only the transport call is guarded. handle_response runs outside this
      # block so the typed error it raises is not caught and re-wrapped as a
      # generic "Connection error" -- which previously flattened every API
      # error to the base SendLayerError.
      response =
        begin
          http.request(request)
        rescue Timeout::Error
          raise SendLayerError.new("Request timed out after #{@timeout}s")
        rescue StandardError => e
          raise SendLayerError.new("Connection error: #{e.message}")
        end

      handle_response(response)
    end

    private

    def build_request(method, uri, data)
      request =
        case method.to_s.upcase
        when 'GET'    then Net::HTTP::Get.new(uri)
        when 'DELETE' then Net::HTTP::Delete.new(uri)
        when 'POST'
          req = Net::HTTP::Post.new(uri)
          req.body = data.to_json if data
          req['Content-Type'] = 'application/json'
          req
        else
          raise SendLayerError.new("Unsupported HTTP method: #{method}")
        end

      request['User-Agent'] = "SendLayer-Ruby/#{::SendLayer::VERSION}"
      @headers.each { |key, value| request[key.to_s] = value }
      # Applied after the caller's headers so those cannot drop authentication.
      request['Authorization'] = "Bearer #{@api_key}"
      request
    end

    def handle_response(response)
      status = response.code.to_i
      return parse_success(response, status) if status.between?(200, 299)

      raise build_error(response, status)
    end

    def parse_success(response, status)
      # Successful responses with no body (e.g. 204 No Content) decode to {}
      # rather than raising out of JSON.parse.
      body = response.body
      return {} if body.nil? || body.empty?

      data =
        begin
          JSON.parse(body)
        rescue JSON::ParserError
          raise SendLayerError.new('Invalid JSON response from API', status)
        end

      data.is_a?(Hash) || data.is_a?(Array) ? data : {}
    end

    # Map an error response onto the appropriate SendLayer error.
    def build_error(response, status)
      data = parse_body(response)
      errors = extract_errors(data)
      error_class, default = ERROR_MAP[status]

      unless error_class
        default = status.between?(500, 599) ? 'Server error' : 'API request failed'
        return SendLayerAPIError.new(extract_message(data, default), status, data, errors)
      end

      error_class.new(extract_message(data, default), status, data, errors)
    end

    # Decode an error response body.
    #
    # Falls back to the HTTP reason phrase when the body isn't JSON, so an HTML
    # error page from a proxy still produces a usable message instead of raising
    # a JSON::ParserError out of the SDK.
    def parse_body(response)
      data =
        begin
          response.body.nil? || response.body.empty? ? nil : JSON.parse(response.body)
        rescue JSON::ParserError
          nil
        end

      return data if data.is_a?(Hash)

      { 'Error' => reason_phrase(response) }
    end

    def reason_phrase(response)
      phrase = response.message
      phrase.nil? || phrase.empty? ? 'Unknown error' : phrase
    end

    # Normalize the SendLayer +Errors+ array from a decoded body.
    #
    # SendLayer returns errors as:
    #
    #   {"Errors": [{"Code": 14, "Message": "..."}]}
    #
    # Returns an empty array when absent or malformed.
    def extract_errors(data)
      raw = data['Errors']
      return [] unless raw.is_a?(Array)

      raw.select { |entry| entry.is_a?(Hash) }
    end

    # Build a message from the API response, preferring its own text.
    #
    # Joins multiple +Errors+ messages with "; ", then falls back to the
    # singular +Error+ key, then to +default+.
    def extract_message(data, default)
      parts = extract_errors(data).filter_map do |entry|
        message = entry['Message']
        message.to_s unless message.nil? || message.to_s.empty?
      end
      return parts.join('; ') unless parts.empty?

      error = data['Error']
      return error if error.is_a?(String) && !error.empty?

      default
    end
  end
end
