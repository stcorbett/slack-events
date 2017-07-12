require 'rails_helper'

feature 'Updating a Slack channel with event information' do
  fixtures :events
  let(:channel)       { EventsChannel.new }
  let(:slack_client)  { double("Slack::Web::Client", chat_postMessage: nil) }
  let(:event)         { Event.first }

  before do
    allow(channel).to receive(:slack_client) { slack_client }
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
    let(:event_day)       { Date.new(2017, 7, 11) }

    let(:heading_message) { "1 event today" }
    let(:heading_params)  { hash_including({channel: '#event-feed', text: a_string_including(heading_message)}) }

    let(:event_message)   { "mHUB and New Mobility Lab" }
    let(:event_params)    { event_params_hash({title: a_string_including(event_message)}) }

    let(:summary_message) { "value propositions associated with Level 4 and 5 autonomous vehicles" }
    let(:summary_params)  { event_params_hash({text: a_string_including(summary_message)}) }

    def event_params_hash(attachment_attribute_match)
      hash_including({
        channel: '#event-feed',
        attachments: [
          a_hash_including(attachment_attribute_match),
        ]
      })
    end

    before do
      channel.publish_events_digest(event_day)
    end

    it "should send information for today's events to Slack" do
      expect(slack_client).to have_received(:chat_postMessage).with(heading_params)
      expect(slack_client).to have_received(:chat_postMessage).with(event_params)
      expect(slack_client).to have_received(:chat_postMessage).with(summary_params)
    end
  end
end
