require "test_helper"

module Voting
  class ChangeVoteTest < ActiveSupport::TestCase
    setup do
      @event = Event.create!(billetto_event_id: "like-event", title: "Jazz show", starts_at: 1.day.from_now)
      @stream = "EventVotes$#{@event.id}"
    end

    test "liking the same event twice keeps one vote and one fact" do
      2.times { change_to("liked") }

      assert_equal 1, @event.votes.liked.count
      assert_instance_of EventUpvoted, Rails.configuration.event_store.read.stream(@stream).to_a.sole
    end

    test "switching and undo change the projection without losing vote history" do
      change_to(nil)
      change_to("liked")
      vote_id = @event.votes.sole.id

      change_to("disliked")
      assert_equal vote_id, @event.votes.sole.id
      assert_predicate @event.votes.sole, :disliked?

      2.times { change_to(nil) }
      assert_empty @event.votes
      facts = Rails.configuration.event_store.read.stream(@stream).to_a
      assert_equal [ EventUpvoted, EventDownvoted, EventVoteRemoved ], facts.map(&:class)
    end

    test "rolls back the fact and vote when the projection fails" do
      store = RailsEventStore::JSONClient.new
      store.subscribe(->(fact) do
        ProjectCurrentVote.new.call(fact)
        raise "Projection failed"
      end, to: [ EventUpvoted ])

      handler = ChangeVoteHandler.new(event_store: store)
      command = ChangeVote.new(event_id: @event.id, clerk_user_id: "user_test", reaction: "liked")

      assert_raises(RuntimeError, match: "Projection failed") { handler.call(command) }

      assert_empty @event.votes
      assert_empty store.read.stream(@stream).to_a
    end

    private

    def change_to(reaction)
      command = ChangeVote.new(event_id: @event.id, clerk_user_id: "user_test", reaction: reaction)
      Rails.configuration.command_bus.call(command)
    end
  end
end
