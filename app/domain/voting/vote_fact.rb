module Voting
  class VoteFact < RubyEventStore::Event
    SCHEMA = { event_id: Integer, clerk_user_id: String }.freeze

    def self.strict(data:)
      unless data.is_a?(Hash) && data.size == SCHEMA.size && SCHEMA.all? { |key, type| data[key].is_a?(type) }
        raise ArgumentError, "A vote fact requires an integer event_id and a string clerk_user_id"
      end

      new(data: data)
    end

    def stream_names
      [ "EventVotes$#{data.fetch(:event_id)}" ]
    end
  end
end
