require "test_helper"

class AccountNavigationTest < ActionView::TestCase
  tests ApplicationHelper
  helper_method :clerk

  test "shows logout when the Clerk middleware supplies a user session" do
    @clerk = Clerk::Proxy.new(session_claims: { "sub" => "user_test" })

    render partial: "layouts/account_navigation"

    assert_select "button[data-action='clerk#signOut']", text: "Log out"
    assert_select "a[href='/sign-in'], a[href='/sign-up']", count: 0
  end

  private

  attr_reader :clerk
end
