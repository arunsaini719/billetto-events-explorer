class Vote < ApplicationRecord
  belongs_to :event

  enum :reaction, { liked: "liked", disliked: "disliked" }, validate: true

  validates :clerk_user_id, presence: true

  def self.reactions_for_events(event_ids, clerk_user_id:)
    return {} if clerk_user_id.blank?

    where(event_id: event_ids, clerk_user_id: clerk_user_id).pluck(:event_id, :reaction).to_h
  end
end
