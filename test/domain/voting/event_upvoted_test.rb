require "test_helper"

module Voting
  class EventUpvotedTest < ActiveSupport::TestCase
    test "a vote fact declares its data and listing stream" do
      data = { event_id: 42, clerk_user_id: "user_test" }
      fact = EventUpvoted.strict(data: data)

      assert_equal data, fact.data
      assert_equal [ "EventVotes$42" ], fact.stream_names
    end

    test "strict rejects a payload without the required types or fields" do
      assert_raises(ArgumentError) { EventUpvoted.strict(data: { event_id: "42", clerk_user_id: "user_test" }) }
      assert_raises(ArgumentError) { EventUpvoted.strict(data: { event_id: 42 }) }
    end
  end
end
