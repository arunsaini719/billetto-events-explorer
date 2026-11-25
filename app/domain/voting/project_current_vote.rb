module Voting
  class ProjectCurrentVote
    def call(fact)
      vote = Vote.find_or_initialize_by(
        event_id: fact.data.fetch(:event_id),
        clerk_user_id: fact.data.fetch(:clerk_user_id)
      )
      case fact
      when EventUpvoted
        vote.update!(reaction: :liked)
      when EventDownvoted
        vote.update!(reaction: :disliked)
      when EventVoteRemoved
        vote.destroy! if vote.persisted?
      end
    end
  end
end
