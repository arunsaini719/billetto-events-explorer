namespace :billetto do
  desc "Fetch and upsert public events from Billetto"
  task import: :environment do
    Billetto::ImportEvents.new(logger: Logger.new($stdout)).call
  rescue Billetto::Error => error
    abort "Billetto import failed: #{error.message}. Previously saved listings were kept."
  end
end
