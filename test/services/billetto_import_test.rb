require "test_helper"
require "stringio"

class BillettoImportTest < ActiveSupport::TestCase
  Response = Data.define(:code, :body) do
    def success?
      code.between?(200, 299)
    end
  end

  test "follows the cursor and upserts listings by Billetto ID" do
    cursor = "https://billetto.dk/api/v3/public/events?after=001&limit=100"
    requested = []
    title = "Friday Jazz Session"
    transport = ->(uri, headers, query:) do
      assert_equal "test-key:test-secret", headers.fetch("Api-Keypair")
      requested << [ uri.to_s, query ]
      if uri.to_s == cursor
        response(data: [ listing(id: "002", title: "Saturday Show") ], has_more: false)
      else
        response(data: [ listing(title:) ], has_more: true, next_url: cursor)
      end
    end
    log = StringIO.new
    importer = importer_for(transport, logger: Logger.new(log))

    assert_difference "Event.count", 2 do
      result = importer.call
      assert_equal [ 2, 2, 0 ], [ result.pages, result.saved, result.skipped ]
    end
    assert_includes log.string, "Fetching public events from Billetto..."
    assert_includes log.string, "Page 1: 1 saved and 0 skipped so far."
    assert_includes log.string, "Page 2: 2 saved and 0 skipped so far."
    assert_includes log.string, "Saved 2 listings from 2 pages; skipped 0 invalid listings."
    assert_equal [ [ Billetto::PublicEvents::ENDPOINT.to_s, { limit: 100 } ], [ cursor, nil ] ], requested

    event = Event.find_by!(billetto_event_id: "001")
    assert_equal Time.utc(2030, 6, 1, 8, 30), event.starts_at
    assert_equal "https://billetto.dk/e/001?utm_source=billetto", event.billetto_url
    assert_equal "https://billetto.imgix.net/example", event.image_url

    title = "Updated title"
    assert_no_difference "Event.count" do
      importer.call
    end
    assert_equal "Updated title", event.reload.title
  end

  test "public events accepts a custom page size" do
    events = public_events_for(->(uri, _, query:) do
      assert_nil uri.query
      assert_equal({ limit: 10 }, query)
      response(data: [])
    end)

    assert_equal [ [] ], events.each_public_page(limit: 10).to_a
  end

  test "leaves page size validation to Billetto" do
    events = public_events_for(->(_, _, query:) do
      assert_equal({ limit: 101 }, query)
      Response.new(400, "")
    end)

    error = assert_raises(Billetto::Error) { events.each_public_page(limit: 101).to_a }
    assert_match "HTTP 400", error.message
  end

  test "public events stops if Billetto sends a previously visited page URL" do
    calls = 0
    events = public_events_for(->(*) do
      calls += 1
      response(data: [], has_more: true, next_url: "?after=001&limit=100")
    end)

    assert_raises(Billetto::Error) { events.each_public_page.to_a }
    assert_equal 2, calls
  end

  test "skips invalid rows but accepts a listing without an end time" do
    rows = [ listing(startdate: nil), listing(id: "002", startdate: "2030-02-30T10:30:00Z"),
             listing(id: "003", enddate: "2030-06-01T08:30:00Z"), listing(id: "004", enddate: nil) ]

    log = StringIO.new
    result = importer_for(->(*) { response(data: rows) }, logger: Logger.new(log)).call

    assert_equal 3, result.skipped
    assert_equal 1, result.saved
    assert_nil Event.find_by!(billetto_event_id: "004").ends_at
    assert_includes log.string, %q(Skipped "001": Starts at can't be blank)
    assert_includes log.string, 'Skipped "002": startdate is not a valid ISO 8601 timestamp'
    assert_includes log.string, 'Skipped "003": Ends at must be greater than'
  end

  test "a failed later request leaves already saved listings intact" do
    transport = ->(uri, _, query:) do
      if uri.query.to_s.include?("after")
        Response.new(503, "")
      else
        response(data: [ listing ], has_more: true, next_url: "?after=001&limit=100")
      end
    end

    error = assert_raises(Billetto::Error) { importer_for(transport).call }
    assert_match "HTTP 503", error.message
    assert Event.exists?(billetto_event_id: "001")
  end

  test "rejects pagination links to an unexpected host" do
    calls = 0
    transport = ->(*) do
      calls += 1
      response(data: [], has_more: true, next_url: "https://other.example/api/v3/public/events")
    end

    assert_raises(Billetto::Error) { importer_for(transport).call }
    assert_equal 1, calls
  end

  test "the adapter never sends credentials to another host" do
    adapter = Billetto::Adapter.new(api_keypair: "test-key:test-secret", transport: ->(*) { flunk "Unexpected HTTP request" })

    assert_raises(Billetto::Error) { adapter.get("//other.example/events") }
  end

  test "rejects malformed response JSON" do
    assert_raises(Billetto::Error) do
      importer_for(->(*) { Response.new(200, "not JSON") }).call
    end
  end

  test "skips non-text titles and drops unsafe optional URLs" do
    rows = [ listing(title: { name: "Not a title" }), listing(id: "002", image_link: "javascript:example") ]

    result = importer_for(->(*) { response(data: rows) }).call

    assert_equal 1, result.skipped
    assert_nil Event.find_by!(billetto_event_id: "002").image_url
  end

  test "can import normalized rows from a fake events resource without HTTP" do
    fake_events = Class.new do
      def each_public_page
        yield [ { billetto_event_id: "fake-1", title: "Fake listing", starts_at: Time.utc(2030, 1, 1) } ]
      end
    end.new

    result = Billetto::ImportEvents.new(events: fake_events).call

    assert_equal 1, result.saved
    assert Event.exists?(billetto_event_id: "fake-1")
  end

  private

  def importer_for(transport, logger: Rails.logger)
    Billetto::ImportEvents.new(events: public_events_for(transport), logger:)
  end

  def public_events_for(transport)
    adapter = Billetto::Adapter.new(api_keypair: "test-key:test-secret", transport: transport)
    Billetto::PublicEvents.new(adapter: adapter)
  end

  def response(**payload)
    Response.new(200, payload.to_json)
  end

  def listing(**overrides)
    {
      id: "001", title: "Example event", description: "Live music",
      startdate: "2030-06-01T10:30:00+02:00", enddate: "2030-06-01T10:30:00Z",
      image_link: "https://billetto.imgix.net/example", url: "https://billetto.dk/e/001?utm_source=billetto"
    }.merge(overrides)
  end
end
