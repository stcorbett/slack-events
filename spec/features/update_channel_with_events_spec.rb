require 'rails_helper'

feature 'Updating a Slack channel with event information' do
  fixtures :events
  let(:channel)       { EventsChannel.new }
  let(:slack_client)  { double("Slack::Web::Client") }
  let(:event)         { Event.first }

  before do
    allow(channel).to receive(:slack_client) { slack_client }
    allow(slack_client).to receive(:chat_postMessage)
  end

  context "updated event information" do
    let(:new_name)        { "Bigger Better Event Name" }
    let(:edit_message)    { "Name was edited" }
    let(:expected_params) { hash_including(channel: '#event-feed', text: a_string_including(edit_message)) }

    before do
      event.name = new_name
      event.save!

      channel.publish_event_changes([event])
    end

    it "should send the updated information to Slack" do
      expect(slack_client).to have_received(:chat_postMessage).with(expected_params)
    end
  end

  context "printing the day's event digest" do
    let(:event_day)   { Date.new(2017, 7, 11) }

    before do
      # EventsChannel.new.publish_events_digest(event_day)
    end

    it "should send information for today's events to Slack" do

    end
  end
end
