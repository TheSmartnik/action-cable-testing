Feature: have_broadcasted_to matcher

  The `have_broadcasted_to` (also aliased as `broadcast_to`) matcher is used to check if a message has been broadcasted to a given record.

  Scenario: broadcasting to a record
    Given a file named "spec/channels/chat_channel_spec.rb" with:
    """ruby
      require "rails_helper"
      require_relative "../../test/stubs/user"

      RSpec.describe ChatChannel, :type => :channel do
        let(:user) { User.new(42) }

        before do
          stub_connection user_id: 42
          subscribe(room_id: 1)
        end

        it "successfully broadcasts message to user" do
          expect { perform :greeting }.to have_broadcasted_to(user)
        end
      end

    """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass
