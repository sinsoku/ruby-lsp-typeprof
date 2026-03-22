# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/addon"

# Stub TypeProf::CodePosition for tests (TypeProf may not be loaded)
unless defined?(TypeProf::CodePosition)
  module TypeProf
    module Core; end
    CodePosition = Struct.new(:lineno, :column)
  end
end

module Ruby
  module Lsp
    module Typeprof
      class CompletionListenerTest < Test::Unit::TestCase
        # T001: Test CompletionListener returns completion items from service
        test "completion_listener fetches completions from service" do
          items = []
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |item| items << item }

          mock_service = Object.new
          mock_service.define_singleton_method(:completion) do |_path, _trigger, _pos, &blk|
            blk.call(:foo, "String#foo : () -> Integer")
            blk.call(:bar, "String#bar : (String) -> String")
          end

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          mock_node = Object.new
          mock_location = Object.new
          mock_location.define_singleton_method(:start_line) { 5 }
          mock_location.define_singleton_method(:start_column) { 3 }
          mock_node.define_singleton_method(:location) { mock_location }

          node_context = Object.new
          node_context.define_singleton_method(:node) { mock_node }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          Ruby::Lsp::Typeprof::CompletionListener.new(
            response_builder, node_context, dispatcher, uri, mock_service, mutex
          )

          assert_equal 2, items.size
        end

        # T002: Test CompletionListener returns empty when no completions available
        test "completion_listener handles nil service gracefully" do
          items = []
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |item| items << item }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::CompletionListener.new(
            response_builder, node_context, dispatcher, uri, nil, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::CompletionListener, listener
          assert_empty items
        end

        # T003: Test CompletionListener rescues exceptions safely
        test "completion_listener rescues service exceptions" do
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |*_args| nil }

          mock_service = Object.new
          mock_service.define_singleton_method(:completion) { |*_args, &_blk| raise "completion error" }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/test.rb" }

          mock_node = Object.new
          mock_location = Object.new
          mock_location.define_singleton_method(:start_line) { 1 }
          mock_location.define_singleton_method(:start_column) { 0 }
          mock_node.define_singleton_method(:location) { mock_location }

          node_context = Object.new
          node_context.define_singleton_method(:node) { mock_node }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          assert_nothing_raised do
            Ruby::Lsp::Typeprof::CompletionListener.new(
              response_builder, node_context, dispatcher, uri, mock_service, mutex
            )
          end
        end
      end
    end
  end
end
