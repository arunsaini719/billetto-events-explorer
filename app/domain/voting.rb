module Voting
  def self.subscriptions
    { ProjectCurrentVote => [ EventUpvoted ] }
  end
end
