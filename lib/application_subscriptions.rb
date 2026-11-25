module ApplicationSubscriptions
  def self.register(event_store)
    handlers.each do |handler, event_types|
      event_store.subscribe(handler.new, to: event_types)
    end
  end

  def self.handlers
    Voting.subscriptions
  end
end
