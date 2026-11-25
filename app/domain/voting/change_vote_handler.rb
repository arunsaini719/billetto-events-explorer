module Voting
  class ChangeVoteHandler
    FACTS = { "liked" => EventUpvoted, "disliked" => EventDownvoted, nil => EventVoteRemoved }.freeze

    def initialize(event_store:)
      @event_store = event_store
    end

    def call(command)
      event = Event.find(command.event_id)
      fact_type = FACTS.fetch(command.reaction)

      event.with_lock(requires_new: true) do
        current_reaction = event.votes.find_by(clerk_user_id: command.clerk_user_id)&.reaction
        next if current_reaction == command.reaction

        fact = fact_type.strict(data: { event_id: event.id, clerk_user_id: command.clerk_user_id })
        @event_store.publish(fact, stream_name: fact.stream_names.first)
      end

      event
    end
  end
end
