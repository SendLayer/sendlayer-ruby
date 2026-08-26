require 'net/http'
require 'uri'
require 'base64'
require 'securerandom'

# Optional dependency for MIME type detection
begin
  require 'mime/types'
  MIME_TYPES_AVAILABLE = true
rescue LoadError
  MIME_TYPES_AVAILABLE = false
end

module SendLayer
  class Emails
    def initialize(client)
      @client = client
    end

    def send(from:, to:, subject:, text: nil, html: nil, cc: nil, bcc: nil, reply_to: nil,
             attachments: nil, headers: nil, tags: nil)

      # Empty strings are treated as absent, so a caller passing text: '' gets a
      # validation error rather than an email with no body.
      has_html = !html.nil? && html != ''
      has_text = !text.nil? && text != ''

      # Validate required parameters
      raise SendLayerValidationError.new("Either 'text' or 'html' content must be provided") unless has_html || has_text

      # Prepare email data
      email_data = {
        From: normalize_recipient(from, 'sender'),
        To: normalize_recipients(to, 'recipient'),
        Subject: subject
      }

      # Both parts are sent when both are supplied. The previous if/else could
      # only ever emit one of them, which silently dropped the plain-text part.
      # HTML wins for the declared content type whenever an HTML body is present.
      email_data[:ContentType] = has_html ? 'HTML' : 'Text'
      email_data[:HTMLContent] = html if has_html
      email_data[:PlainContent] = text if has_text
      email_data[:CC] = normalize_recipients(cc) if cc
      email_data[:BCC] = normalize_recipients(bcc) if bcc
      email_data[:ReplyTo] = normalize_recipients(reply_to, 'reply_to') if reply_to
      email_data[:Headers] = headers if headers

      if tags
        unless tags.is_a?(Array) && tags.all? { |t| t.is_a?(String) }
          raise SendLayerValidationError.new('Tags must be a list of strings')
        end
        email_data[:Tags] = tags
      end

      # Handle attachments
      if attachments && !attachments.empty?
        email_data[:Attachments] = process_attachments(attachments)
      end

      @client.make_request('POST', 'email', email_data)
    end

    private

    def normalize_recipient(recipient, role = 'recipient')
      case recipient
      when String
        validate_email(recipient, role)
        { email: recipient }
      when Hash
        validate_email(recipient[:email] || recipient['email'], role)
        {
          email: recipient[:email] || recipient['email'],
          name: recipient[:name] || recipient['name']
        }.compact
      else
        raise SendLayerValidationError.new("Invalid #{role} format: #{recipient.class}")
      end
    end

    def normalize_recipients(recipients, role = 'recipient')
      return nil if recipients.nil?

      case recipients
      when String
        [normalize_recipient(recipients, role)]
      when Array
        recipients.map { |r| normalize_recipient(r, role) }
      else
        raise SendLayerValidationError.new("Invalid #{role}s format: #{recipients.class}")
      end
    end

    def validate_email(email, role = 'recipient')
      email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      unless email_regex.match?(email)
        raise SendLayerValidationError.new("Invalid #{role} email address: #{email}")
      end
      email
    end

    def process_attachments(attachments)
      attachments.map do |attachment|
        case attachment
        when Hash
          path = attachment[:path] || attachment['path']
          type = attachment[:type] || attachment['type']
          if path.nil? || (path.respond_to?(:strip) && path.strip.empty?)
            raise SendLayerValidationError.new("Attachment path is required")
          end
          encoded_content = read_attachment_content(path)
          {
            Content: encoded_content,
            Type: type || detect_content_type(path),
            Filename: File.basename(path),
            Disposition: "attachment",
            ContentID: SecureRandom.random_number(2**31 - 1)
          }
        when String
          encoded_content = read_attachment_content(attachment)
          {
            Content: encoded_content,
            Type: detect_content_type(attachment),
            Filename: File.basename(attachment),
            Disposition: "attachment",
            ContentID: SecureRandom.random_number(2**31 - 1)
          }
        else
          raise SendLayerValidationError.new("Invalid attachment format: #{attachment.class}")
        end
      end
    end

    def read_attachment_content(path)
      uri = URI.parse(path) rescue nil
      is_url = uri && (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS))

      if is_url
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.is_a?(URI::HTTPS)
        timeout_ms = (@client.attachment_url_timeout || 30000)
        http.read_timeout = (timeout_ms.to_f / 1000.0)
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise SendLayerValidationError.new("Error fetching remote file: HTTP #{response.code}")
        end
        return Base64.strict_encode64(response.body)
      end

      unless File.exist?(path)
        raise SendLayerValidationError.new("Attachment file not found: #{path}")
      end

      content = File.binread(path)
      Base64.strict_encode64(content)
    rescue => e
      raise SendLayerValidationError.new("Error reading attachment: #{e.message}")
    end

    def detect_content_type(path)
      if MIME_TYPES_AVAILABLE
        mime_type = MIME::Types.type_for(path).first
        mime_type ? mime_type.content_type : 'application/octet-stream'
      else
        # Fallback to basic file extension detection
        case File.extname(path).downcase
        when '.pdf'
          'application/pdf'
        when '.txt'
          'text/plain'
        when '.html', '.htm'
          'text/html'
        when '.jpg', '.jpeg'
          'image/jpeg'
        when '.png'
          'image/png'
        when '.gif'
          'image/gif'
        else
          'application/octet-stream'
        end
      end
    end
  end
end
