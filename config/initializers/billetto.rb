Rails.application.config.to_prepare do
  Rails.configuration.billetto = Billetto::Adapter.new(api_keypair: ENV["BILLETTO_API_KEYPAIR"])
end
