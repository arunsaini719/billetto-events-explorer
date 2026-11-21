Clerk.configure do |config|
  config.logger = Logger.new(STDOUT)

  offline_test = Rails.env.test? && ENV["RUN_LIVE_CLERK_TEST"] != "1"
  config.excluded_routes = if !offline_test && config.publishable_key.present? && config.secret_key.present?
    [ "/up", "/assets/*" ]
  else
    [ "/*" ]
  end
end
