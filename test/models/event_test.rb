require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires a Billetto ID, title, and valid start time" do
    event = Event.new(starts_at: "not a date")

    assert_not event.valid?
    assert_equal [ :billetto_event_id, :starts_at, :title ], event.errors.attribute_names.sort
  end

  test "an end time is optional but must be after the start" do
    event = Event.new(event_attributes)
    assert event.valid?

    event.ends_at = event.starts_at - 1.minute
    assert_not event.valid?
    assert event.errors[:ends_at].any?

    event.ends_at = event.starts_at
    assert_not event.valid?

    event.ends_at = event.starts_at + 1.minute
    assert event.valid?
  end

  test "Postgres rejects a duplicate Billetto ID" do
    Event.create!(event_attributes)

    assert_raises ActiveRecord::RecordNotUnique do
      Event.transaction(requires_new: true) { Event.create!(event_attributes) }
    end
  end

  private

  def event_attributes
    { billetto_event_id: "2098457", title: "Friday Jazz Session", starts_at: 1.day.from_now }
  end
end
