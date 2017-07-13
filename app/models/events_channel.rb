class EventsChannel
  def initialize

  end

  def slack_client
    @client ||= Slack::Web::Client.new
  end

  def bot_user_id
    @bot_user_id ||= slack_client.auth_test[:user_id]
  end

  def pinned_items
    slack_client.pins_list(channel: configured_channel).items
  end

  def unpin_previously_pinned_messages
    bot_messages = pinned_items.select do |message|
      message.created_by == bot_user_id && message.type == "message"
    end

    bot_messages.each do |message|
      slack_client.pins_remove(channel: configured_channel, timestamp: message.message.ts)
    end
  end

  def last_bot_message
    messages = slack_client.channels_history(channel: configured_channel).messages
    message_to_pin = messages.find do |message|
      message.user == bot_user_id &&
        message.type == "message" &&
        message.subtype != "pinned_item"
    end
  end

  def pin_last_bot_message
    return unless message = last_bot_message

    slack_client.pins_add(channel: configured_channel, timestamp: message.ts)
  end

  def publish_events_digest(date=Date.today)
    events = events_for(date) || []
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
      next unless text.present?

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
      event_range = [date.in_time_zone..(date.in_time_zone + 1.day + 6.hours)]
      Event.where(start_time: event_range).order(start_time: :asc)
    end

    def configured_channel
      channel_name = ENV.fetch("EVENTS_CHANNEL") { "event-feed" }
      channel_name.gsub!(/^#/, "")
      channel_name.prepend("#")

      channel_name
    end
end
