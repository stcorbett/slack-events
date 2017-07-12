class EventTextBuilder
  include ActionView::Helpers::TextHelper
  extend  ActionView::Helpers::TextHelper

  TIME_FORMAT = "%D %-l:%M%p"

  attr_accessor :event

  def initialize(event)
    @event = event
  end

  def self.date_heading(date, events)
    heading = "*#{date.strftime("%B")} #{date.day.ordinalize}, #{date.year}* "
    heading += "#{pluralize events.size, 'event'} today"
    heading
  end

  # Event name, start time, (location if not at mHUB)
  # *The Autonomous Vehicle Alliance Info Session* 2:00pm - 90 minutes
  def summary(include_name: true)
    detail_text = "#{slack_date_and_time(event.start_time)} - #{duration_text}"

    if include_name
      "#{name_text} #{detail_text}"
    else
      detail_text
    end
  end

  # eg:
  # "<a href="event">unchanged-shortname</a>: Venue changed to <b>mHUB Classroom</b> now <b>starts at 2PM</b> on <b>Tuesday, November 3rd</b>. name and description were edited"
  def previous_changes_summary
    return unless event.previous_changes.slice(*change_attributes).present?

    if event.created
      message = summary
      message.prepend("*New event* ")
    else
      detail_text = [important_changes_summary, copy_changes_summary].reject(&:blank?).join(" ")
      message = "#{name_text}: #{detail_text}"
    end

    message
  end

  def short_name
    if event.previous_changes["name"] && event.previous_changes["name"][0].present?
      event_name = event.previous_changes["name"][0]
    else
      event_name = event.name
    end

    truncate(event_name.squish, length: 60, separator: /\W/)
  end

  def duration_text
    duration_minutes = (event.end_time - event.start_time) / 60
    duration_hours = duration_minutes / 60

    if duration_hours < 1.0
      pluralize(duration_minutes, "minute")
    else
      pluralize(duration_hours, "hour")
    end
  end

  private
    def slack_date_and_time(time)
      "<!date^#{time.to_i}^{time} {date_short_pretty}|#{time.strftime(TIME_FORMAT)}>"
    end

    def escape_html(message)
      escaped = message
      # negative lookahead to escape '&' unless it's part of an escaped html character
      escaped.gsub!(/&(?!amp;|lt;|gt;)/, "&amp;")
      escaped.gsub!("<", "&lt;")
      escaped.gsub!(">", "&gt;")

      escaped
    end

    def name_text
      "<#{event.people_vine_url}|#{short_name}>"
    end

    def change_attributes
      copy_change_attributes + ["venue", "start_time", "end_time"]
    end

    def copy_change_attributes
      ["name", "description", "summary", "image"]
    end

    # replicate as attachment objects where changes are shown as fields with titles and values
    def important_changes_summary
      important_changes = [venue_change_summary, time_changes_summary].reject(&:blank?)
      return unless important_changes.present?

      important_changes.join(" ").lstrip.capitalize + "."
    end

    def venue_change_summary
      return unless event.previous_changes["venue"]

      new_venue = event.previous_changes["venue"][1]
      venue_text = truncate(new_venue.squish, length: 40, separator: /\W/)

      "Venue changed to *#{venue_text}*"
    end

    def time_changes_summary
      changes = []
      date_change_text = ""

      if event.previous_changes["start_time"].present?
        new_start = event.previous_changes["start_time"][1]

        changes << "starts at *#{slack_date_and_time(new_start)}*" if new_start.present?

        old_date = event.previous_changes["start_time"][0]
        old_date = old_date.to_date if old_date.present?
        new_date = event.previous_changes["start_time"][1].to_date

        if old_date != new_date
          date_change_text = "on *#{new_date.strftime("%A, %B ") + new_date.day.ordinalize }*"
        end
      end

      if event.previous_changes["end_time"].present?
        new_end = event.previous_changes["end_time"][1]

        changes << "ends at *#{slack_date_and_time(new_end)}*" if new_end.present?
      end

      return unless changes.present? || date_change_text.present?

      time_messages = [changes.join(" and "), date_change_text].join(" ").strip
      "now #{time_messages}"
    end

    def copy_changes_summary
      changes = copy_change_attributes.select do |attribute|
        event.previous_changes[attribute.to_s]
      end
      return unless changes.present?

      if changes.size == 1
        change_text = changes.first
        join_text = "was"
      elsif changes.size == 2
        change_text = changes.join(" and ")
        join_text = "were"
      else
        change_text = [changes[0...-1].join(", "), changes[-1]].join(" and ")
        join_text = "were"
      end

      "#{change_text} #{join_text} edited.".capitalize
    end
end
