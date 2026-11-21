class SessionsController < ApplicationController
  before_action :mark_auth_page

  def sign_in
    render :show, locals: { mode: "sign-in", title: "Sign in" }
  end

  def sign_up
    render :show, locals: { mode: "sign-up", title: "Sign up" }
  end

  private

  def mark_auth_page
    @auth_page = true
  end
end
