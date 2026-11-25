require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "requires an event, a Clerk user ID, and a supported reaction" do
    vote = Vote.new(reaction: "other")

    assert_not vote.valid?
    assert_equal [ :clerk_user_id, :event, :reaction ], vote.errors.attribute_names.sort
  end

  test "changing a reaction keeps one current vote" do
    event = create_event
    vote = event.votes.create!(clerk_user_id: "user_test", reaction: :liked)
    assert_predicate vote.reload, :liked?

    assert_no_difference -> { event.votes.count } do
      vote.update!(reaction: :disliked)
    end
    assert_predicate vote.reload, :disliked?
  end

  test "Postgres allows different voters but rejects a second vote from the same user" do
    event = create_event
    event.votes.create!(clerk_user_id: "user_one", reaction: :liked)
    event.votes.create!(clerk_user_id: "user_two", reaction: :disliked)

    assert_raises ActiveRecord::RecordNotUnique do
      Vote.transaction(requires_new: true) do
        event.votes.create!(clerk_user_id: "user_one", reaction: :disliked)
      end
    end
    assert_equal 2, event.votes.count
  end

  test "loads only the current voter's reactions across the event batch" do
    event = create_event
    other_event = Event.create!(billetto_event_id: "other-event", title: "Other event", starts_at: 2.days.from_now)
    event.votes.create!(clerk_user_id: "user_one", reaction: :liked)
    event.votes.create!(clerk_user_id: "user_two", reaction: :disliked)
    other_event.votes.create!(clerk_user_id: "user_two", reaction: :liked)

    assert_equal({ event.id => "liked" }, Vote.reactions_for_events([ event.id, other_event.id ], clerk_user_id: "user_one"))
    assert_empty Vote.reactions_for_events([ event.id, other_event.id ], clerk_user_id: nil)
  end

  private

  def create_event
    Event.create!(billetto_event_id: "vote-test", title: "Example event", starts_at: 1.day.from_now)
  end
end
