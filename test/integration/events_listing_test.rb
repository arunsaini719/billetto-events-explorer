require "test_helper"

class EventsListingTest < ActionDispatch::IntegrationTest
  test "shows only upcoming events, soonest first" do
    Event.create!(billetto_event_id: "past", title: "Past show", starts_at: 1.day.ago)
    Event.create!(billetto_event_id: "later", title: "Later show", starts_at: 2.days.from_now)
    Event.create!(billetto_event_id: "soon", title: "Soon show", starts_at: 1.day.from_now,
                  description: "<p>Music and more</p>", billetto_url: "https://billetto.dk/e/soon?utm_source=test")

    get root_path

    assert_response :success
    assert_select("#event-listings h2", count: 2) do |headings|
      assert_equal [ "Soon show", "Later show" ], headings.map(&:text)
    end
    assert_select "article p", text: "Music and more"
    assert_select "a[target='_blank'][rel='noopener'][href=?]",
                  "https://billetto.dk/e/soon?utm_source=test", text: "View on Billetto"
    assert_select "#events-pagination a", count: 0
  end

  test "shows vote counts to guests without offering the vote forms" do
    event = Event.create!(billetto_event_id: "likes", title: "Popular show", starts_at: 1.day.from_now)
    event.votes.create!(clerk_user_id: "user_one", reaction: :liked)
    event.votes.create!(clerk_user_id: "user_two", reaction: :disliked)

    get root_path

    assert_select "#votes_event_#{event.id}" do
      assert_select "[data-vote-count='liked']", text: "1"
      assert_select "[data-vote-count='disliked']", text: "1"
      assert_select "form", count: 0
    end
  end

  test "loads the next batch as a Turbo Stream and removes the button on the last page" do
    starts_at = 1.day.from_now.change(usec: 123_456)
    events = 25.times.map do |index|
      Event.create!(billetto_event_id: "example-#{index}", title: "Show #{index}", starts_at: starts_at)
    end

    get root_path
    assert_select "#event-listings article", count: 24
    next_url = css_select("#events-pagination a").sole["href"]

    Event.create!(billetto_event_id: "new-earlier", title: "New earlier show", starts_at: starts_at - 1.hour)
    events[23].update!(starts_at: starts_at - 30.minutes)

    get next_url, headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_select "turbo-stream[action='append'][target='event-listings'] article h2", count: 1 do |headings|
      assert_equal [ events.last.title ], headings.map(&:text)
    end
    assert_select "turbo-stream[action='replace'][target='events-pagination'] a", count: 0
  end
end
