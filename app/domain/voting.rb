module Voting
  def self.subscriptions
    { ProjectCurrentVote => [ EventUpvoted, EventDownvoted, EventVoteRemoved ] }
  end
end
