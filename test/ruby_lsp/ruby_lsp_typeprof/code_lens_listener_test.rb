# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class CodeLensListenerTest < Test::Unit::TestCase
      test "rescues service exceptions and logs them to outgoing_queue" do
        mock_service = stub(code_lens: nil)
        mock_service.stubs(:code_lens).raises("something went wrong")
        outgoing_queue = Thread::Queue.new

        build_listener(service: mock_service, outgoing_queue: outgoing_queue)

        notification = outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(/Ruby LSP TypeProf failed to compute code lens/, notification.params.message)
        assert_match(/something went wrong/, notification.params.message)
        assert_equal ::RubyLsp::Constant::MessageType::ERROR, notification.params.type
      ensure
        outgoing_queue&.close
      end

      private

      def build_listener(service:, outgoing_queue:)
        response_builder = stub(:<< => nil)
        dispatcher = stub(register: nil)
        uri = stub(to_standardized_path: "/tmp/test.rb")

        CodeLensListener.new(
          response_builder, uri, dispatcher, service, Mutex.new, outgoing_queue
        )
      end
    end
  end
end
