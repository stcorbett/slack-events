class EventsChannel
  def initialize

  end

  def slack_client
    @client ||= Slack::Web::Client.new
  end

  # TODO: slack formatting
  #         show event description as drop down style content in the slack message
  def publish_events_digest(date=Date.today)
    return unless events_for(date).present?

    messages = messages_for(date, events_for(date))
    messages.each do |message|
      text = escape_html message

      slack_client.chat_postMessage({
        channel: configured_channel,
        text: text,
        as_user: true
      })
    end
  end

  def publish_event_changes(events)
    events.each do |event|
      text = escape_html event.previous_changes_summary

      slack_client.chat_postMessage({
        channel: configured_channel,
        text: text,
        as_user: true
      })
    end
  end

  private
    def escape_html(message)
      escaped = message
      # negative lookahead to escape '&' unless it's part of an escaped html character
      escaped.gsub!(/&(?!amp;|lt;|gt;)/, "&amp;")
      escaped.gsub!("<", "&lt;")
      escaped.gsub!(">", "&gt;")

      escaped
    end

    def events_for(date)
      event_range = [date.to_time..(date.to_time + 1.day + 6.hours)]
      Event.where(start_time: event_range)
    end

    def messages_for(date, events)
      messages = [EventTextBuilder.date_heading(date, events)]

      events.each do |event|
        messages << event.slack_summary
      end

      messages
    end

    def configured_channel
      channel_name = ENV.fetch("EVENTS_CHANNEL") { "event-feed" }
      channel_name.gsub!(/^#/, "")
      channel_name.prepend("#")

      channel_name
    end
end
