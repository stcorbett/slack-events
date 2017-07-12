namespace :event_feed do

  desc "store events from the feed - Event#create/update notifies the slack channel"
  task :store_events => :environment do
    published_events = EventsFeed.new.store_published_events!
    EventsChannel.new.publish_event_changes(published_events)
  end

  desc "publish today's events"
  task :publish_today => :environment do
    EventsChannel.new.publish_events_digest
    EventsChannel.new.unpin_previously_pinned_messages
    EventsChannel.new.pin_last_bot_message
  end
end

# TODO:
#   smoke-tests:
#     See digest messages and changes messages published to a temporary slack channel
#       load fixtures, run things
#     See new events load into development database (run the rake tasks)

#   deploy
#     create heroku app
#     deploy/migrate
#     configure for the mHUB slack and the right channel
#     run the content of the rake tasks in console, see messages published to slack
#     set up scheduler jobs to run the rake tasks
#       look for updates every hour
#       send the digest every morning at 7
