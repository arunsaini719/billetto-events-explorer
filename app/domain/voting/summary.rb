module Voting
  Summary = Data.define(:likes, :dislikes) do
    def self.for_events(event_ids)
      counts = Vote.where(event_id: event_ids).group(:event_id, :reaction).count

      event_ids.index_with do |id|
        new(likes: counts.fetch([ id, "liked" ], 0), dislikes: counts.fetch([ id, "disliked" ], 0))
      end
    end
  end
end
