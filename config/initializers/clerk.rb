Clerk.configure do |config|
  config.logger = Logger.new(STDOUT)

  config.excluded_routes = if config.publishable_key.present? && config.secret_key.present?
    [ "/up", "/assets/*" ]
  else
    [ "/*" ]
  end
end
