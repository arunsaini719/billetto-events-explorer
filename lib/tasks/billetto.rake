namespace :billetto do
  desc "Fetch and upsert public events from Billetto"
  task import: :environment do
    result = Billetto::ImportEvents.new.call
    puts "Saved #{result.saved} listings from #{result.pages} pages; skipped #{result.skipped} invalid listings."
  rescue Billetto::Error => error
    abort "Billetto import failed: #{error.message}. Previously saved listings were kept."
  end
end
