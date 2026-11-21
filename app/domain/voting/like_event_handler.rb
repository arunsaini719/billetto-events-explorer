module Voting
  class LikeEventHandler
    def initialize(event_store:)
      @event_store = event_store
    end

    def call(command)
      event = Event.find(command.event_id)

      event.with_lock(requires_new: true) do
        next if event.votes.liked.exists?(clerk_user_id: command.clerk_user_id)

        fact = EventUpvoted.strict(data: { event_id: event.id, clerk_user_id: command.clerk_user_id })
        @event_store.publish(fact, stream_name: fact.stream_names.first)
      end

      event
    end
  end
end
