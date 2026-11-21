class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_enum :vote_reaction, %w[liked disliked]

    create_table :votes do |t|
      t.references :event, null: false, foreign_key: true, index: false
      t.string :clerk_user_id, null: false
      t.enum :reaction, enum_type: :vote_reaction, null: false
      t.timestamps

      t.index [ :event_id, :clerk_user_id ], unique: true
    end
  end
end
