require "test_helper"

class VotesControllerTest < ActionController::TestCase
  setup do
    @event = Event.create!(billetto_event_id: "vote-controller", title: "Jazz show", starts_at: 1.day.from_now)
  end

  test "redirects an anonymous browser request without recording a vote" do
    assert_no_difference "Vote.count" do
      put :update, params: { event_id: @event.id }
    end

    assert_response :see_other
    assert_redirected_to sign_in_path
    assert_empty event_facts
  end

  test "redirects an anonymous Turbo request to sign in" do
    put :update, params: { event_id: @event.id }, format: :turbo_stream

    assert_response :see_other
    assert_redirected_to sign_in_path
    assert_empty event_facts
  end

  test "returns unauthorized for an anonymous JSON request" do
    put :update, params: { event_id: @event.id }, format: :json

    assert_response :unauthorized
    assert_empty event_facts
  end

  test "rejects a session without a user ID" do
    use_clerk_session(user_id: nil)

    put :update, params: { event_id: @event.id }

    assert_response :see_other
    assert_redirected_to sign_in_path
    assert_empty @event.votes
    assert_empty event_facts
  end

  test "records a like for the Clerk user, not a submitted identity" do
    use_clerk_session

    assert_difference "Vote.count", 1 do
      put :update, params: { event_id: @event.id, reaction: "liked", clerk_user_id: "user_forged" }
    end

    assert_response :see_other
    assert_redirected_to root_path(anchor: "event_#{@event.id}")
    assert_predicate @event.votes.find_by!(clerk_user_id: "user_verified"), :liked?
    fact = event_facts.sole
    assert_instance_of Voting::EventUpvoted, fact
    assert_equal({ event_id: @event.id, clerk_user_id: "user_verified" }, fact.data)
  end

  test "a user can switch to dislike" do
    use_clerk_session
    vote = @event.votes.create!(clerk_user_id: "user_verified", reaction: :liked)

    assert_no_difference "Vote.count" do
      put :update, params: { event_id: @event.id, reaction: "disliked" }
    end

    assert_response :see_other
    assert_predicate vote.reload, :disliked?
    assert_instance_of Voting::EventDownvoted, event_facts.sole
  end

  test "undo clears the current vote and records the removal" do
    use_clerk_session
    @event.votes.create!(clerk_user_id: "user_verified", reaction: :liked)

    assert_difference "Vote.count", -1 do
      delete :destroy, params: { event_id: @event.id }
    end

    assert_response :see_other
    assert_instance_of Voting::EventVoteRemoved, event_facts.sole
  end

  test "a Turbo vote replaces only the event's vote controls and counts" do
    use_clerk_session
    @event.votes.create!(clerk_user_id: "user_other", reaction: :disliked)
    @event.votes.create!(clerk_user_id: "user_another", reaction: :liked)

    put :update, params: { event_id: @event.id, reaction: "liked" }, format: :turbo_stream

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_select "turbo-stream[action='replace'][target=?]", "votes_event_#{@event.id}", count: 1 do
      assert_select "[data-vote-count='liked']", text: "2"
      assert_select "[data-vote-count='disliked']", text: "1"
      assert_select "button[aria-label='Like'][aria-pressed='true']"
      assert_select "button[aria-label='Dislike'][aria-pressed='false']"
    end
    active_button = css_select("button[aria-pressed='true']").sole
    assert_equal "delete", active_button.ancestors("form").first.at_css("input[name='_method']")["value"]
    assert_select "turbo-stream", count: 1
  end

  test "clicking the active vote again clears the highlight and preserves other users' votes" do
    use_clerk_session
    @event.votes.create!(clerk_user_id: "user_verified", reaction: :liked)
    @event.votes.create!(clerk_user_id: "user_other", reaction: :liked)

    delete :destroy, params: { event_id: @event.id }, format: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[target=?]", "votes_event_#{@event.id}" do
      assert_select "[data-vote-count='liked']", text: "1"
      assert_select "[data-vote-count='disliked']", text: "0"
      assert_select "button[aria-pressed='false']", count: 2
      assert_select "input[name='_method'][value='delete']", count: 0
    end
  end

  test "invalid reactions are rejected without recording a fact" do
    use_clerk_session

    put :update, params: { event_id: @event.id, reaction: "invalid" }

    assert_response :unprocessable_content
    assert_empty event_facts
  end

  private

  def use_clerk_session(user_id: "user_verified")
    @request.env["clerk"] = Clerk::Proxy.new(session_claims: { "sub" => user_id })
  end

  def event_facts
    Rails.configuration.event_store.read.stream("EventVotes$#{@event.id}").to_a
  end
end
