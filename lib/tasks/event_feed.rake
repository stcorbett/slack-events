namespace :event_feed do

  desc ""
  task :xxx => :environment do
    # load json, create/update events
    #   updates will trigger EventsFeed to publish to Slack
  end

  desc ""
  task :xxx => :environment do
    # publish event digest
    #   send the day's events to EventsFeed to be published
    #   defaults to today
  end

end
