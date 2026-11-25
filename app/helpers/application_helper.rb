module ApplicationHelper
  def clerk_frontend_origin
    ENV["CLERK_FRONTEND_API_URL"].to_s.delete_suffix("/")
  end

  def clerk_publishable_key
    ENV["CLERK_PUBLISHABLE_KEY"]
  end

  def clerk_frontend_configured?
    clerk_publishable_key.present? && clerk_frontend_origin.start_with?("https://")
  end

  def clerk_signed_in?
    clerk&.user_id.present?
  end

  def show_account_navigation?
    clerk_frontend_configured? && !@auth_page
  end

  def clerk_browser_needed?
    clerk_frontend_configured? && (@auth_page || clerk_signed_in?)
  end

  def page_body_attributes
    attributes = {}
    attributes[:class] = "auth-layout" if @auth_page
    if clerk_browser_needed?
      attributes[:data] = { controller: "clerk", action: "turbo:before-cache@document->clerk#unmount" }
    end
    attributes
  end
end
