module Voting
  class ProjectCurrentVote
    def call(fact)
      vote = Vote.find_or_initialize_by(
        event_id: fact.data.fetch(:event_id),
        clerk_user_id: fact.data.fetch(:clerk_user_id)
      )
      vote.update!(reaction: :liked)
    end
  end
end
