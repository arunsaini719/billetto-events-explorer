class Event < ApplicationRecord
  has_many :votes

  validates :billetto_event_id, :title, :starts_at, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at }, if: -> { starts_at.present? && ends_at.present? }
end
