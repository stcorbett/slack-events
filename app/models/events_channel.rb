class EventsChannel
  def initialize

  end

  def slack_client
    @client ||= Slack::Web::Client.new
  end

  def publish_events_digest(date=Date.today)
    # get the text, compose it, send it out
    #   summary of the day (*January 5th, 2017* 3 events today)
    #   line-items for individual events
  end

  def publish_event_changes(events)
    events.each do |event|
      slack_client.chat_postMessage(channel: configured_channel, text: event.previous_changes_summary, as_user: true)
    end
  end

  private
    def configured_channel
      channel_name = ENV.fetch("EVENTS_CHANNEL") { "event-feed" }
      channel_name.gsub!(/^#/, "")
      channel_name.prepend("#")

      channel_name
    end
end
