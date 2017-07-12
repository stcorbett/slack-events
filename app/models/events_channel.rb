class EventsChannel
  def initialize

  end

  def slack_client
    @client ||= Slack::Web::Client.new
  end

  def publish_events_digest(date=Date.today)
    return unless events_for(date).present?

    events = events_for(date)
    slack_client.chat_postMessage({
      channel:      configured_channel,
      attachments:  events.map(&:slack_summary_attachment),
      text:         EventTextBuilder.date_heading(date, events),
      as_user:      true
    })
  end

  def publish_event_changes(events)
    events.each do |event|
      text = event.previous_changes_summary

      slack_client.chat_postMessage({
        channel: configured_channel,
        text: text,
        as_user: true,
        unfurl_links: false,
      })
    end
  end

  def publish_text(text)
    slack_client.chat_postMessage({
      channel: configured_channel,
      text: text,
      as_user: true
    })
  end

  private
    def events_for(date)
      event_range = [date.to_time..(date.to_time + 1.day + 6.hours)]
      Event.where(start_time: event_range).order(start_time: :asc)
    end

    def configured_channel
      channel_name = ENV.fetch("EVENTS_CHANNEL") { "event-feed" }
      channel_name.gsub!(/^#/, "")
      channel_name.prepend("#")

      channel_name
    end
end
