require "application_system_test_case"

class EventsListingSystemTest < ApplicationSystemTestCase
  test "loads more cards in place without allowing guests to vote" do
    starts_at = 1.day.from_now
    25.times do |index|
      Event.create!(billetto_event_id: "browser-#{index}", title: "Browser event #{index + 1}", starts_at: starts_at)
    end

    visit root_path

    assert_selector "#event-listings article", count: 24
    assert_no_selector "button[aria-label='Like']"
    click_link "Load more events"

    assert_selector "#event-listings article", count: 25
    assert_selector "h2", text: "Browser event 25", exact_text: true
    assert_no_link "Load more events"
    assert_current_path root_path, ignore_query: true
  end
end
