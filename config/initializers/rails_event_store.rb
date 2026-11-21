Rails.application.config.to_prepare do
  event_store = RailsEventStore::JSONClient.new
  ApplicationSubscriptions.register(event_store)
  Rails.configuration.event_store = event_store

  command_bus = Arkency::CommandBus.new
  command_bus.register(Voting::LikeEvent, Voting::LikeEventHandler.new(event_store: event_store))
  Rails.configuration.command_bus = command_bus
end
