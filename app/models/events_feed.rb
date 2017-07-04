class EventsFeed

  def initialize
  end

  def store_published_events!
    published_events = events_from_feed
    saved_events = []

    published_events.each do |event|
      if existing_event = Event.find_by(identifier: event.identifier)
        existing_event.attributes = event.attributes.except("id", "created_at", "updated_at")
        existing_event.save!
        saved_events << existing_event
      else
        event.save!
        saved_events << event
      end
    end

    saved_events
  end

  private
    def feed_response
      @feed_response ||= Faraday.get ENV.fetch("EVENTS_URL") { "http://mhubchicago.com/pageh/22890/event-stream.js" }
    end

    def people_vine_parser(response_body)
      response_body.gsub!("<script>data=", "")
      response_body.gsub!(";</script><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div>", "")
      JSON.parse response_body
    end

    def people_vine_event_from(peoplevine_event_hash)
      {
        event_feed_name:  "peoplevine",
        feed_response:    peoplevine_event_hash,
        name:             peoplevine_event_hash["event_title"],
        description:      peoplevine_event_hash["event_description"],
        summary:          peoplevine_event_hash["event_summary"],
        identifier:       peoplevine_event_hash["event_no"],
        venue:            peoplevine_event_hash["event_venue"],
        image:            peoplevine_event_hash["event_graphic"],
        start_time:       peoplevine_event_hash["event_date"],
        end_time:         peoplevine_event_hash["event_date_end"],
      }
    end

    def events_from_feed
      event_data = people_vine_parser(feed_response.body)

      event_data.collect do |event_hash|
        Event.new people_vine_event_from(event_hash)
      end
    end

end
