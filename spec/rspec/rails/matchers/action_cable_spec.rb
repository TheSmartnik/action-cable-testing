require "spec_helper"
require "rspec/rails/feature_check"

if RSpec::Rails::FeatureCheck.has_action_cable?
  require "rspec/rails/matchers/action_cable"
end

RSpec.describe "ActionCable matchers", :skip => !RSpec::Rails::FeatureCheck.has_action_cable? do
  def make_broadcast(stream, msg)
    ActionCable.server.broadcast stream, msg
  end

  before do
    server = ActionCable.server
    test_adapter = ActionCable::SubscriptionAdapter::Test.new(server)
    server.instance_variable_set(:@pubsub, test_adapter)
  end

  describe 'have_broadcasted_to' do
    it 'broadcasts to object' do
      binding.pry
      expect {
        make_broadcast('stream', 'hello')
      }.to have_broadcasted('stream')
    end
  end

  describe "have_broadcasted" do
    it "raises ArgumentError when no Proc passed to expect" do
      expect {
        expect(true).to have_broadcasted('stream')
      }.to raise_error(ArgumentError)
    end

    it "passes with default messages count (exactly one)" do
      expect {
        make_broadcast('stream', 'hello')
      }.to have_broadcasted('stream')
    end

    it "passes when using alias" do
      expect {
        make_broadcast('stream', 'hello')
      }.to broadcast('stream')
    end

    it "counts only messages sent in block" do
      make_broadcast('stream', 'one')
      expect {
        make_broadcast('stream', 'two')
      }.to have_broadcasted('stream').exactly(1)
    end

    it "passes when negated" do
      expect { }.not_to have_broadcasted('stream')
    end

    it "fails when message is not sent" do
      expect {
        expect { }.to have_broadcasted('stream')
      }.to raise_error(/expected to broadcast exactly 1 messages to stream, but broadcast 0/)
    end

    it "fails when too many messages make_broadcast" do
      expect {
        expect {
          make_broadcast('stream', 'one')
          make_broadcast('stream', 'two')
        }.to have_broadcasted('stream').exactly(1)
      }.to raise_error(/expected to broadcast exactly 1 messages to stream, but broadcast 2/)
    end

    it "reports correct number in fail error message" do
      make_broadcast('stream', 'one')
      expect {
        expect { }.to have_broadcasted('stream').exactly(1)
      }.to raise_error(/expected to broadcast exactly 1 messages to stream, but broadcast 0/)
    end

    it "fails when negated and message is sent" do
      expect {
        expect { make_broadcast('stream', 'one') }.not_to have_broadcasted('stream')
      }.to raise_error(/expected not to broadcast exactly 1 messages to stream, but broadcast 1/)
    end

    it "passes with multiple streams" do
      expect {
        make_broadcast('stream_a', 'A')
        make_broadcast('stream_b', 'B')
        make_broadcast('stream_c', 'C')
      }.to have_broadcasted('stream_a').and have_broadcasted('stream_b')
    end

    it "passes with :once count" do
      expect {
        make_broadcast('stream', 'one')
      }.to have_broadcasted('stream').exactly(:once)
    end

    it "passes with :twice count" do
      expect {
        make_broadcast('stream', 'one')
        make_broadcast('stream', 'two')
      }.to have_broadcasted('stream').exactly(:twice)
    end

    it "passes with :thrice count" do
      expect {
        make_broadcast('stream', 'one')
        make_broadcast('stream', 'two')
        make_broadcast('stream', 'three')
      }.to have_broadcasted('stream').exactly(:thrice)
    end

    it "passes with at_least count when sent messages are over limit" do
      expect {
        make_broadcast('stream', 'one')
        make_broadcast('stream', 'two')
      }.to have_broadcasted('stream').at_least(:once)
    end

    it "passes with at_most count when sent messages are under limit" do
      expect {
        make_broadcast('stream', 'hello')
      }.to have_broadcasted('stream').at_most(:once)
    end

    it "generates failure message with at least hint" do
      expect {
        expect { }.to have_broadcasted('stream').at_least(:once)
      }.to raise_error(/expected to broadcast at least 1 messages to stream, but broadcast 0/)
    end

    it "generates failure message with at most hint" do
      expect {
        expect {
          make_broadcast('stream', 'hello')
          make_broadcast('stream', 'hello')
        }.to have_broadcasted('stream').at_most(:once)
      }.to raise_error(/expected to broadcast at most 1 messages to stream, but broadcast 2/)
    end

    it "passes with provided data" do
      expect {
        make_broadcast('stream', id: 42, name: "David")
      }.to have_broadcasted('stream').with(id: 42, name: "David")
    end

    it "passes with provided data matchers" do
      expect {
        make_broadcast('stream', id: 42, name: "David", message_id: 123)
      }.to have_broadcasted('stream').with(a_hash_including(name: "David", id: 42))
    end

    it "generates failure message when data not match" do
      expect {
        expect {
          make_broadcast('stream', id: 42, name: "David", message_id: 123)
        }.to have_broadcasted('stream').with(a_hash_including(name: "John", id: 42))
      }.to raise_error(/expected to broadcast exactly 1 messages to stream with a hash including/)
    end

    it "throws descriptive error when no test adapter set" do
      require "action_cable/subscription_adapter/inline"
      ActionCable.server.instance_variable_set(:@pubsub, ActionCable::SubscriptionAdapter::Inline)
      expect {
        expect { make_broadcast('stream', 'hello') }.to have_broadcasted('stream')
      }.to raise_error("To use ActionCable matchers set `adapter: :test` in your cable.yml")
    end

    it "fails with with block with incorrect data" do
      expect {
        expect {
          make_broadcast('stream', "asdf")
        }.to have_broadcasted('stream').with { |data|
          expect(data).to eq("zxcv")
        }
      }.to raise_error { |e|
        expect(e.message).to match(/expected: "zxcv"/)
        expect(e.message).to match(/got: "asdf"/)
      }
    end
  end
end
