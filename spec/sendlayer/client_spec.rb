require 'spec_helper'

RSpec.describe SendLayer::Client do
  let(:api_key) { 'test-key' }
  let(:client) { described_class.new(api_key) }
  let(:endpoint) { 'https://console.sendlayer.com/api/v1/email' }

  def stub_email(status:, body:, headers: {})
    stub_request(:post, endpoint).to_return(status: status, body: body, headers: headers)
  end

  def send_request
    client.make_request('POST', 'email', { Subject: 'hi' })
  end

  describe 'error mapping' do
    {
      400 => SendLayer::SendLayerValidationError,
      401 => SendLayer::SendLayerAuthenticationError,
      404 => SendLayer::SendLayerNotFoundError,
      422 => SendLayer::SendLayerValidationError,
      429 => SendLayer::SendLayerRateLimitError,
      500 => SendLayer::SendLayerInternalServerError
    }.each do |status, error_class|
      it "raises #{error_class} for HTTP #{status}" do
        stub_email(status: status, body: '{}')
        expect { send_request }.to raise_error(error_class)
      end
    end

    it 'raises SendLayerAPIError for an unmapped 4xx' do
      stub_email(status: 418, body: '{}')
      expect { send_request }.to raise_error(SendLayer::SendLayerAPIError)
    end

    it 'raises SendLayerAPIError for a 5xx other than 500' do
      stub_email(status: [503, 'Service Unavailable'], body: '')
      expect { send_request }.to raise_error(SendLayer::SendLayerAPIError, /503/)
    end

    it 'prefixes SendLayerAPIError messages with the status' do
      stub_email(status: 418, body: { 'Error' => 'teapot' }.to_json)
      expect { send_request }.to raise_error(SendLayer::SendLayerAPIError, 'API Error 418: teapot')
    end
  end

  describe 'message extraction' do
    it "surfaces the API's own message from the Errors array" do
      stub_email(status: 401, body: { 'Errors' => [{ 'Code' => 14, 'Message' => 'Invalid API key supplied' }] }.to_json)
      expect { send_request }.to raise_error(SendLayer::SendLayerAuthenticationError, 'Invalid API key supplied')
    end

    it 'joins multiple Errors messages with a semicolon' do
      body = { 'Errors' => [{ 'Code' => 1, 'Message' => 'Bad from' }, { 'Code' => 2, 'Message' => 'Bad to' }] }.to_json
      stub_email(status: 422, body: body)
      expect { send_request }.to raise_error(SendLayer::SendLayerValidationError, 'Bad from; Bad to')
    end

    it 'falls back to the singular Error key' do
      stub_email(status: 400, body: { 'Error' => 'Missing subject' }.to_json)
      expect { send_request }.to raise_error(SendLayer::SendLayerValidationError, 'Missing subject')
    end

    it 'falls back to the built-in default when the body carries no message' do
      stub_email(status: 429, body: '{}')
      expect { send_request }.to raise_error(SendLayer::SendLayerRateLimitError, 'Rate limit exceeded')
    end

    it 'falls back to the HTTP reason phrase for a non-JSON error body' do
      stub_email(status: [502, 'Bad Gateway'], body: '<html>proxy error</html>')
      expect { send_request }.to raise_error(SendLayer::SendLayerAPIError, 'API Error 502: Bad Gateway')
    end

    it 'ignores malformed entries in the Errors array' do
      stub_email(status: 400, body: { 'Errors' => ['nope', { 'Message' => 'real' }] }.to_json)
      expect { send_request }.to raise_error(SendLayer::SendLayerValidationError, 'real')
    end
  end

  describe 'error attributes' do
    it 'exposes status_code, response, errors and codes on every error type' do
      body = { 'Errors' => [{ 'Code' => 14, 'Message' => 'nope' }] }
      stub_email(status: 401, body: body.to_json)

      begin
        send_request
        raise 'expected an error'
      rescue SendLayer::SendLayerError => e
        expect(e).to be_a(SendLayer::SendLayerAuthenticationError)
        expect(e.status_code).to eq(401)
        expect(e.response).to eq(body)
        expect(e.errors).to eq([{ 'Code' => 14, 'Message' => 'nope' }])
        expect(e.codes).to eq([14])
      end
    end

    it 'defaults the attributes for a locally raised error' do
      error = SendLayer::SendLayerError.new('local')
      expect(error.status_code).to be_nil
      expect(error.response).to eq({})
      expect(error.errors).to eq([])
      expect(error.codes).to eq([])
    end

    it 'skips entries with no Code in #codes' do
      error = SendLayer::SendLayerError.new('x', 400, {}, [{ 'Message' => 'no code' }, { 'Code' => 7 }])
      expect(error.codes).to eq([7])
    end
  end

  describe 'success responses' do
    it 'decodes an empty body to an empty hash' do
      stub_request(:delete, 'https://console.sendlayer.com/api/v1/webhooks/1')
        .to_return(status: 204, body: '')
      expect(client.make_request('DELETE', 'webhooks/1')).to eq({})
    end

    it 'raises SendLayerError for an undecodable success body' do
      stub_email(status: 200, body: '<html>not json</html>')
      expect { send_request }.to raise_error(SendLayer::SendLayerError, 'Invalid JSON response from API')
    end

    it 'returns parsed JSON objects' do
      stub_email(status: 200, body: { 'MessageID' => 'abc' }.to_json)
      expect(send_request).to eq({ 'MessageID' => 'abc' })
    end
  end

  describe 'timeouts' do
    it 'defaults to 30 seconds' do
      expect(client.timeout).to eq(30)
    end

    it 'honours an explicit timeout' do
      expect(described_class.new(api_key, timeout: 5).timeout).to eq(5)
    end

    it 'raises SendLayerError rather than a Net::HTTP exception' do
      stub_request(:post, endpoint).to_timeout
      expect { send_request }.to raise_error(SendLayer::SendLayerError, /timed out after 30s/)
    end

    it 'wraps a connection failure as SendLayerError' do
      stub_request(:post, endpoint).to_raise(SocketError.new('getaddrinfo failed'))
      expect { send_request }.to raise_error(SendLayer::SendLayerError, /Connection error/)
    end
  end

  describe 'headers' do
    it 'sends the Authorization and User-Agent headers' do
      stub_email(status: 200, body: '{}')
      send_request
      expect(WebMock).to have_requested(:post, endpoint)
        .with(headers: { 'Authorization' => "Bearer #{api_key}",
                         'User-Agent' => "SendLayer-Ruby/#{SendLayer::VERSION}" })
    end

    it 'merges caller-supplied headers without dropping authentication' do
      configured = described_class.new(api_key, headers: { 'X-Trace' => 'abc' })
      stub_email(status: 200, body: '{}')
      configured.make_request('POST', 'email', { Subject: 'hi' })
      expect(WebMock).to have_requested(:post, endpoint)
        .with(headers: { 'X-Trace' => 'abc', 'Authorization' => "Bearer #{api_key}" })
    end

    it 'does not let a caller header override Authorization' do
      configured = described_class.new(api_key, headers: { 'Authorization' => 'Bearer hijacked' })
      stub_email(status: 200, body: '{}')
      configured.make_request('POST', 'email', { Subject: 'hi' })
      expect(WebMock).to have_requested(:post, endpoint)
        .with(headers: { 'Authorization' => "Bearer #{api_key}" })
    end
  end

  describe 'configuration' do
    it 'defaults attachment_url_timeout to 30000ms' do
      expect(client.attachment_url_timeout).to eq(30_000)
    end

    it 'is forwarded from the SendLayer entry point' do
      sdk = SendLayer::SendLayer.new(api_key, timeout: 7, attachment_url_timeout: 1234)
      inner = sdk.instance_variable_get(:@client)
      expect(inner.timeout).to eq(7)
      expect(inner.attachment_url_timeout).to eq(1234)
    end

    it 'rejects an unsupported HTTP method' do
      expect { client.make_request('PATCH', 'email') }
        .to raise_error(SendLayer::SendLayerError, /Unsupported HTTP method/)
    end
  end
end
