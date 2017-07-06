class Event < ApplicationRecord
  attr_reader :created

  store :feed_response,  coder: JSON
  after_create :set_created_instance_variable

  def self.event_time_zone
    ENV.fetch("EVENT_TIME_ZONE") { 'Central Time (US & Canada)' }
  end
  Time.zone = self.event_time_zone

  def start_time=(time)
    write_attribute(:start_time, time_parsed(time))
  end

  def end_time=(time)
    write_attribute(:end_time, time_parsed(time))
  end

  def description=(string)
    write_attribute(:description, strip_html(string))
  end

  def previous_changes_summary
    text_builder.previous_changes_summary
  end

  def slack_summary
    text_builder.summary
  end

  # need to do these html replacements before storing open text from peoplevine
  # Replace the ampersand, &, with &amp;
  # Replace the less-than sign, < with &lt;
  # Replace the greater-than sign, > with &gt;

  def people_vine_url
    "https://mhubchicago.com/event/#{url_keyword}"
  end

  private
    def text_builder
      @text_builder ||= EventTextBuilder.new(self)
    end

    def timestamp_to_event_time_zone(timestamp)
      # Time interprets timestamps as being based in UTC
      #   eg: Time.zone.at(1498846695810) builds a local time assuming time '0' was in UTC

      # This returns Time in the local zone for timestamps that are based in the local zone
      #   eg: an API where the '1498846695810' timestamp was written assuming time '0' was in the local zone

      Time.zone = "UTC"
      utc_time = Time.zone.at(timestamp)

      Time.zone = self.class.event_time_zone
      Time.zone.local(utc_time.year, utc_time.month, utc_time.day, utc_time.hour, utc_time.min)
    end

    def time_parsed(time)
      return time if time.is_a?(Time) || time.is_a?(DateTime) || time.is_a?(Date)

      if time.match(/Date\(.*\)/)
        js_time = time.match(/Date\((.*)\)/)[1].to_f

        return timestamp_to_event_time_zone(js_time/1000)
      else
        return Time.parse(time)
      end
    end

    def strip_html(string)
      Nokogiri::HTML(string).text
    end

    def set_created_instance_variable
      @created = true
    end
end
