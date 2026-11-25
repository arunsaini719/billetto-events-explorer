require "json"
require "uri"

module Billetto
  class Adapter
    BASE_URL = URI("https://billetto.dk").freeze

    def initialize(api_keypair:, transport: nil)
      @api_keypair = api_keypair
      @transport = transport || method(:http_get)
    end

    def get(path, query: nil)
      if @api_keypair.blank?
        raise Error, "Set BILLETTO_API_KEYPAIR in .env before importing events"
      end

      uri = URI.join(BASE_URL, path)
      unless uri.is_a?(URI::HTTPS) && uri.origin == BASE_URL.origin
        raise Error, "Billetto requests must go to #{BASE_URL.origin}"
      end

      headers = { "Api-Keypair" => @api_keypair, "Accept" => "application/json" }
      response = @transport.call(uri, headers, query:)
      unless response.success?
        raise Error, "Billetto returned HTTP #{response.code}"
      end
      JSON.parse(response.body)
    rescue URI::Error
      raise Error, "Invalid Billetto request URL"
    rescue JSON::ParserError
      raise Error, "Billetto returned invalid JSON"
    rescue HTTParty::Error, Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError
      raise Error, "Could not reach the Billetto API"
    end

    private

    def http_get(uri, headers, query:)
      HTTParty.get(uri.to_s, headers:, query:, open_timeout: 5, read_timeout: 5, follow_redirects: false)
    end
  end
end
