require "test_helper"

class ClerkPagesTest < ActionDispatch::IntegrationTest
  test "home and auth pages work without Clerk configuration" do
    with_clerk_env do
      get root_path
      assert_response :success
      assert_select "script[data-clerk-publishable-key]", count: 0

      get sign_in_path
      assert_response :success
      assert_select "p", text: /Clerk is not configured/
    end
  end

  test "Clerk scripts and account forms are present when configured" do
    with_clerk_env(publishable_key: "pk_test_placeholder", frontend_url: "https://example.clerk.accounts.dev") do
      get root_path
      assert_select "script[data-clerk-publishable-key]", count: 0
      assert_select "a[href=?]", sign_in_path, text: "Sign in"
      assert_select "a[href=?]", sign_up_path, text: "Sign up"
      assert_select "button[data-clerk-target='logout']", count: 0

      { sign_in_path => "sign-in", sign_up_path => "sign-up" }.each do |path, mode|
        get path
        assert_select "script[data-clerk-publishable-key='pk_test_placeholder']", count: 1
        assert_select "[data-clerk-target='form'][data-mode=?]", mode
      end
    end
  end

  private

  def with_clerk_env(publishable_key: nil, frontend_url: nil)
    values = { "CLERK_PUBLISHABLE_KEY" => publishable_key, "CLERK_FRONTEND_API_URL" => frontend_url }
    previous = ENV.to_h.slice(*values.keys)
    ENV.update(values)
    yield
  ensure
    values.each_key { |key| ENV[key] = previous[key] }
  end
end
