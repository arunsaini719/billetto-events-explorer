require "test_helper"

class RailsEventStoreTest < ActiveSupport::TestCase
  test "publishes and reads an event stored as JSONB" do
    store = Rails.configuration.event_store
    event = RubyEventStore::Event.new(data: { event_id: 42, clerk_user_id: "user_test" }, metadata: { source: "smoke-test" })
    stream = "SetupSmoke$#{event.event_id}"

    store.publish(event, stream_name: stream)
    stored = store.read.stream(stream).to_a.sole

    assert_equal event.event_id, stored.event_id
    assert_equal event.data, stored.data
    assert_equal "smoke-test", stored.metadata.fetch(:source)

    db = ActiveRecord::Base.connection
    payload_types = db.select_one(<<~SQL)
      SELECT jsonb_typeof(data) AS data_type, jsonb_typeof(metadata) AS metadata_type
      FROM event_store_events
      WHERE event_id = #{db.quote(event.event_id)}
    SQL
    assert_equal({ "data_type" => "object", "metadata_type" => "object" }, payload_types)
  end
end
