require 'rails_helper'

feature 'Importing events from EVENTS_URL' do
  let(:response_file) { "eleven_events.js" }
  let(:js_response)   { File.join(Rails.root, "spec", response_file) }
  let(:feed)          { EventsFeed.new }

  before do
    Event.destroy_all
    response_body = File.read js_response
    allow(feed).to receive(:feed_response) { double("Faraday::Response", body: response_body) }
  end

  scenario 'the events are stored' do
    feed.store_published_events!
    expect(Event.all.size).to eq(11)
  end

  it "should give access to the events that were just created" do
    published_events = feed.store_published_events!

    published_events.each do |event|
      expect(event.created).to eq(true)
    end
  end

  context 'the events attributes are stored' do
    let(:response_file) { "event.js" }
    let(:event)         { Event.first }
    let(:attrs)         {
      {
        name:         "mHUB and New Mobility Lab Information Session with The Autonomous Vehicle Alliance",
        description:  "The Autonomous Vehicle",
        summary:      "Tim Woods",
        identifier:   "4180",
        venue:        "Classroom",
        image:        "https://peoplevine.blob.core",
        start_time:   Time.zone.local(2017, 07, 11, 14, 00),
        end_time:     Time.zone.local(2017, 07, 11, 15, 30),
      }
    }

    before              { feed.store_published_events! }

    scenario "name" do
      expect(event.name).to include(attrs[:name])
    end

    scenario "description" do
      expect(event.description).to include(attrs[:description])
    end

    scenario "summary" do
      expect(event.summary).to include(attrs[:summary])
    end

    scenario "identifier" do
      expect(event.identifier).to include(attrs[:identifier])
    end

    scenario "venue" do
      expect(event.venue).to include(attrs[:venue])
    end

    scenario "image" do
      expect(event.image).to include(attrs[:image])
    end

    scenario "start time" do
      expect(event.start_time).to eq(attrs[:start_time])
    end

    scenario "end time" do
      expect(event.end_time).to eq(attrs[:end_time])
    end
  end

  context 'with existing events' do
    let(:existing_event_identifier) { "4180" }
    let(:event)                     { Event.find_by( identifier: existing_event_identifier ) }

    before do
      Event.create!({
        identifier:   existing_event_identifier,
        name:         "old name for event"
      })

      @published_events = feed.store_published_events!
    end

    it "should give access to updated events" do
      changed_event = @published_events.find{|e| e.identifier == existing_event_identifier }
      expect(changed_event).to be_present
    end

    scenario "changed events are updated" do
      changed_event = @published_events.find{|e| e.identifier == existing_event_identifier }
      expect(changed_event.previous_changes).to be_present
      expect(changed_event.previous_changes["name"].last).to include("Autonomous Vehicle Alliance")
    end
  end
end
