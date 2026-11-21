class Vote < ApplicationRecord
  belongs_to :event

  enum :reaction, { liked: "liked", disliked: "disliked" }, validate: true

  validates :clerk_user_id, presence: true
end
