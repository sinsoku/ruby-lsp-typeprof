# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class CodeLensListenerTest < Test::Unit::TestCase
      include CaptureStderr

      test "rescues service exceptions" do
        mock_service = stub(code_lens: nil)
        mock_service.stubs(:code_lens).raises("something went wrong")

        output = capture_stderr do
          build_listener(service: mock_service)
        end

        assert_match(/Code lens error: something went wrong/, output)
      end

      private

      def build_listener(service:)
        response_builder = stub(:<< => nil)
        dispatcher = stub(register: nil)
        uri = stub(to_standardized_path: "/tmp/test.rb")

        CodeLensListener.new(
          response_builder, uri, dispatcher, service, Mutex.new
        )
      end
    end
  end
end
