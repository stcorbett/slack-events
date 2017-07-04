namespace :event_feed do

  desc "store events from the feed - Event#create/update notifies the slack channel"
  task :store_events => :environment do
    published_events = EventsFeed.new.store_published_events!
    EventsChannel.new.publish_event_changes(published_events)
  end

  desc "publish today's events"
  task :publish_today => :environment do
    EventsChannel.new.publish_events_digest
  end
end
