require "set"
require "uri"

module Billetto
  class PublicEvents
    ENDPOINT = URI.join(Adapter::BASE_URL, "/api/v3/public/events").freeze

    def initialize(adapter: Rails.configuration.billetto)
      @adapter = adapter
    end

    def each_public_page(limit: 100)
      return enum_for(:each_public_page, limit:) unless block_given?

      uri = ENDPOINT
      page = @adapter.get(uri.request_uri, query: { limit: })
      visited = Set.new

      loop do
        unless page.is_a?(Hash) && page["data"].is_a?(Array)
          raise Error, "Billetto response has no data array"
        end

        yield page.fetch("data").map { |row| EventAttributes.from_api(row) }
        uri = next_page(page, uri)
        break unless uri

        path = uri.request_uri
        raise Error, "Billetto pagination repeated a page" unless visited.add?(path)

        page = @adapter.get(path)
      end
    end

    private

    def next_page(page, current)
      link = page["next_url"]
      return if link.nil? || page["has_more"] == false
      raise Error, "Billetto response has no valid next_url" unless link.is_a?(String) && link.present?

      uri = URI.join(current, link)
      unless uri.is_a?(URI::HTTPS) && uri.origin == ENDPOINT.origin && uri.path == ENDPOINT.path
        raise Error, "Billetto returned an unexpected pagination URL"
      end
      uri
    rescue URI::Error
      raise Error, "Billetto returned a malformed pagination URL"
    end
  end
end
