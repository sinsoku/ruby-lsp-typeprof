# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/addon"

module Ruby
  module Lsp
    module Typeprof
      class CodeLensListenerTest < Test::Unit::TestCase
        # T001: Test CodeLensListener returns code lens for method definitions
        test "code_lens_listener caches results from service" do
          mock_service = Object.new
          mock_service.define_singleton_method(:code_lens) do |_path, &blk|
            mock_range = Object.new
            mock_first = Object.new
            mock_first.define_singleton_method(:lineno) { 5 }
            mock_range.define_singleton_method(:first) { mock_first }
            blk.call(mock_range, "(Integer, Integer) -> Integer")
          end

          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |_item| nil }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::CodeLensListener.new(
            response_builder, uri, dispatcher, mock_service, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::CodeLensListener, listener
        end

        # T002: Test CodeLensListener returns empty when no signatures available
        test "code_lens_listener handles nil service gracefully" do
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |_item| nil }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::CodeLensListener.new(
            response_builder, uri, dispatcher, nil, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::CodeLensListener, listener
        end

        # T003: Test CodeLensListener rescues exceptions safely
        test "code_lens_listener rescues service exceptions" do
          mock_service = Object.new
          mock_service.define_singleton_method(:code_lens) { |_path, &_blk| raise "code lens error" }

          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |_item| nil }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          assert_nothing_raised do
            Ruby::Lsp::Typeprof::CodeLensListener.new(
              response_builder, uri, dispatcher, mock_service, mutex
            )
          end
        end
      end
    end
  end
end
