class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_clerk_user_id

  private

  def current_clerk_user_id
    clerk.user_id.presence if clerk&.session
  end

  def require_clerk_user
    return if current_clerk_user_id

    if request.format.html? || request.format.turbo_stream?
      redirect_to sign_in_path, status: :see_other
    else
      head :unauthorized
    end
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
