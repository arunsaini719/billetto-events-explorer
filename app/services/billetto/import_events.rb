module Billetto
  class ImportEvents
    Result = Data.define(:pages, :saved, :skipped)

    def initialize(events: PublicEvents.new)
      @events = events
    end

    def call
      pages = saved = skipped = 0

      @events.each_public_page do |rows|
        pages += 1
        listings = {}
        rows.each do |attributes|
          if attributes && Event.new(attributes).valid?
            listings[attributes.fetch(:billetto_event_id)] = attributes
          else
            skipped += 1
          end
        end

        if listings.any?
          Event.upsert_all(listings.values, unique_by: :billetto_event_id)
          saved += listings.size
        end
      end

      Result.new(pages:, saved:, skipped:)
    end
  end
end
