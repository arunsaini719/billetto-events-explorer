module Voting
  ChangeVote = Data.define(:event_id, :clerk_user_id, :reaction)
end
