class EventsController < ApplicationController
  include Pagy::Method

  def index
    upcoming = Event.where(starts_at: Time.current..).order(:starts_at, :id)
    @pagy, @events = pagy(:keyset, upcoming, limit: 24, page_key: "after", tuple_comparison: true,
                          pre_serialize: method(:serialize_cutoff))

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def serialize_cutoff(cutoff)
    # Preserve the database's microseconds; Rails JSON defaults to milliseconds.
    cutoff[:starts_at] = cutoff.fetch(:starts_at).iso8601(6)
  end
end
