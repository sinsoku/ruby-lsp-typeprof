# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class SignatureCacheTest < Test::Unit::TestCase
      def setup
        @outgoing_queue = Thread::Queue.new
      end

      def teardown
        @outgoing_queue.close
      end

      test "indexes hints by the start line of each method" do
        service = stub
        service.stubs(:code_lens).with("/tmp/test.rb").multiple_yields(
          [[stub(lineno: 3)], "(Integer) -> String"],
          [[stub(lineno: 10)], "() -> nil"]
        )

        cache = SignatureCache.new(service, Mutex.new, "/tmp/test.rb", @outgoing_queue, feature: "code lens")

        refute cache.empty?
        assert_equal "(Integer) -> String", cache[3]
        assert_equal "() -> nil", cache[10]
        assert_nil cache[4]
      end

      test "is empty and does not query the service when path is nil" do
        service = stub
        service.expects(:code_lens).never

        cache = SignatureCache.new(service, Mutex.new, nil, @outgoing_queue, feature: "document symbol")

        assert cache.empty?
        assert @outgoing_queue.empty?
      end

      test "rescues service exceptions and logs them with the feature name" do
        service = stub
        service.stubs(:code_lens).raises("something went wrong")

        cache = SignatureCache.new(service, Mutex.new, "/tmp/test.rb", @outgoing_queue, feature: "document symbol")

        assert cache.empty?
        notification = @outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(%r{failed to compute document symbol for /tmp/test.rb}, notification.params.message)
        assert_match(/something went wrong/, notification.params.message)
        assert_equal ::RubyLsp::Constant::MessageType::ERROR, notification.params.type
      end
    end
  end
end
