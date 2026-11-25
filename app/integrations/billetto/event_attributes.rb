require "date"
require "uri"

module Billetto
  module EventAttributes
    class << self
      def from_api(row)
        unless row.is_a?(Hash)
          return InvalidListing.new(billetto_event_id: nil, message: "Expected a listing object")
        end

        billetto_event_id = text(row["id"])&.strip
        {
          billetto_event_id:,
          title: text(row["title"])&.strip,
          description: text(row["description"]),
          starts_at: parse_timestamp(row["startdate"], "startdate"),
          ends_at: parse_timestamp(row["enddate"], "enddate"),
          image_url: https_url(row["image_link"]),
          billetto_url: https_url(row["url"])
        }
      rescue ArgumentError => error
        InvalidListing.new(billetto_event_id:, message: error.message)
      end

      private

      def text(value)
        value if value.is_a?(String)
      end

      def parse_timestamp(value, field)
        DateTime.iso8601(value).to_time.utc unless value.nil?
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{field} is not a valid ISO 8601 timestamp"
      end

      def https_url(value)
        return unless value.is_a?(String)

        uri = URI.parse(value)
        value if uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
      rescue URI::Error
        nil
      end
    end
  end
end
