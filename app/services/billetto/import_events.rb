module Billetto
  class ImportEvents
    Result = Data.define(:pages, :saved, :skipped)

    def initialize(events: PublicEvents.new, logger: Rails.logger)
      @events = events
      @logger = logger
    end

    def call
      @logger.info("Fetching public events from Billetto...")
      pages = saved = skipped = 0

      @events.each_public_page do |rows|
        pages += 1
        listings = {}
        invalid = []
        rows.each do |attributes|
          if attributes.is_a?(InvalidListing)
            invalid << attributes
            next
          end

          event = Event.new(attributes)
          if event.valid?
            listings[event.billetto_event_id] = attributes
          else
            invalid << InvalidListing.new(billetto_event_id: event.billetto_event_id, message: event.errors.full_messages.join("; "))
          end
        end
        skipped += invalid.size

        if listings.any?
          Event.upsert_all(listings.values, unique_by: :billetto_event_id)
          saved += listings.size
        end

        @logger.info("Page #{pages}: #{saved} saved and #{skipped} skipped so far.")
        invalid.each { |listing| log_invalid(listing) }
      end

      @logger.info("Saved #{saved} listings from #{pages} pages; skipped #{skipped} invalid listings.")
      Result.new(pages:, saved:, skipped:)
    end

    private

    def log_invalid(listing)
      id = listing.billetto_event_id.presence&.inspect || "(no Billetto ID)"
      @logger.warn("Skipped #{id}: #{listing.message}")
    end
  end
end
