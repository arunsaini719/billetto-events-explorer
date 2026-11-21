class VotesController < ApplicationController
  before_action :require_clerk_user

  def update
    command = Voting::LikeEvent.new(event_id: params[:event_id], clerk_user_id: current_clerk_user_id)
    event = command_bus.call(command)
    redirect_to root_path(anchor: helpers.dom_id(event)), status: :see_other
  end
end
