require "application_system_test_case"

class ClerkVotingSystemTest < ApplicationSystemTestCase
  test "signs up, votes, logs out, and signs back in with Clerk" do
    skip "Set RUN_LIVE_CLERK_TEST=1 to use a dedicated Clerk test instance" unless ENV["RUN_LIVE_CLERK_TEST"] == "1"
    assert ENV["CLERK_PUBLISHABLE_KEY"].to_s.start_with?("pk_test_"), "Use a Clerk development publishable key"
    assert ENV["CLERK_SECRET_KEY"].to_s.start_with?("sk_test_"), "Use a Clerk development secret key"

    event = Event.create!(billetto_event_id: "clerk-browser", title: "Clerk browser show", starts_at: 1.day.from_now)
    suffix = SecureRandom.hex(8)
    email = "explorer+clerk_test_#{suffix}@example.com"
    password = "Explorer-#{SecureRandom.hex(12)}!"
    install_clerk_testing_token

    sign_up(email, password)
    within("#votes_event_#{event.id}") do
      find("button[aria-label='Like']").click
      assert_selector "button[aria-label='Like'][aria-pressed='true']"
      assert_selector "[data-vote-count='liked']", exact_text: "1"
    end

    sign_out
    assert_no_selector "button[aria-label='Like']"

    sign_in(email, password)
    within("#votes_event_#{event.id}") do
      assert_selector "button[aria-label='Like'][aria-pressed='true']"
      find("button[aria-label='Dislike']").click
      assert_selector "button[aria-label='Dislike'][aria-pressed='true']"
      assert_selector "[data-vote-count='liked']", exact_text: "0"
      assert_selector "[data-vote-count='disliked']", exact_text: "1"
      find("button[aria-label='Dislike']").click
      assert_selector "button[aria-label='Dislike'][aria-pressed='false']"
      assert_selector "[data-vote-count='disliked']", exact_text: "0"
    end

    sign_out
  end

  private

  def sign_up(email, password)
    visit sign_up_path
    find("input[name='emailAddress']", wait: 20).set(email)
    find("input[name='password']").set(password)
    click_button "Continue", exact: true
    assert_selector "html[data-clerk-verification-ready]", visible: :all, wait: 15
    find("input[aria-label='Enter verification code']").send_keys("424242")
    assert_button "Log out", disabled: false, wait: 20
  end

  def sign_in(email, password)
    click_link "Sign in"
    find("input[name='identifier']", wait: 20).set(email)
    click_button "Continue", exact: true
    find("input[name='password']", wait: 15).set(password)
    click_button "Continue", exact: true
    assert_button "Log out", disabled: false, wait: 20
  end

  def sign_out
    click_button "Log out"
    assert_link "Sign in", wait: 15
  end

  def install_clerk_testing_token
    origin = URI(ENV.fetch("CLERK_FRONTEND_API_URL")).origin
    token = Clerk::SDK.new.testing_tokens.create.testing_token.token

    page.driver.browser.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source: <<~JAVASCRIPT)
      (() => {
        const origin = #{origin.to_json};
        const token = #{token.to_json};
        const originalFetch = window.fetch.bind(window);
        window.fetch = async (input, options) => {
          const url = new URL(input instanceof Request ? input.url : input, location.href);
          if (url.origin !== origin || !url.pathname.startsWith("/v1/")) return originalFetch(input, options);
          url.searchParams.set("__clerk_testing_token", token);
          const response = await originalFetch(input instanceof Request ? new Request(url, input) : url, options);
          if (response.ok && url.pathname.endsWith("/prepare_verification")) {
            document.documentElement.dataset.clerkVerificationReady = "true";
          }
          return response;
        };
      })();
    JAVASCRIPT
  end
end
