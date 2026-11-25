class VotesController < ApplicationController
  before_action :require_clerk_user

  def update
    reaction = params[:reaction]
    return head :unprocessable_content unless Vote.reactions.key?(reaction)

    change_vote(reaction)
  end

  def destroy
    change_vote(nil)
  end

  private

  def change_vote(reaction)
    command = Voting::ChangeVote.new(event_id: params[:event_id], clerk_user_id: current_clerk_user_id, reaction: reaction)
    @event = command_bus.call(command)

    respond_to do |format|
      format.html { redirect_to root_path(anchor: helpers.dom_id(@event)), status: :see_other }
      format.turbo_stream do
        @vote_summary = Voting::Summary.for_events([ @event.id ]).fetch(@event.id)
        @viewer_reaction = @event.votes.where(clerk_user_id: current_clerk_user_id).pick(:reaction)
        render :change
      end
    end
  end
end
