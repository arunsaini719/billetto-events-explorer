require "date"
require "uri"

module Billetto
  module EventAttributes
    class << self
      def from_api(row)
        return unless row.is_a?(Hash)

        {
          billetto_event_id: text(row["id"])&.strip,
          title: text(row["title"])&.strip,
          description: text(row["description"]),
          starts_at: parse_timestamp(row["startdate"]),
          ends_at: parse_timestamp(row["enddate"]),
          image_url: https_url(row["image_link"]),
          billetto_url: https_url(row["url"])
        }
      rescue ArgumentError, TypeError
        nil
      end

      private

      def text(value)
        value if value.is_a?(String)
      end

      def parse_timestamp(value)
        DateTime.iso8601(value).to_time.utc unless value.nil?
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
