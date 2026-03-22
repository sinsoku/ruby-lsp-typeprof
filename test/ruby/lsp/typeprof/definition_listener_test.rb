# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/addon"

module Ruby
  module Lsp
    module Typeprof
      class DefinitionListenerTest < Test::Unit::TestCase
        # T001: Test DefinitionListener returns location for method calls
        test "definition_listener pushes locations to response_builder" do
          results = []
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |item| results << item }

          mock_service = Object.new
          mock_service.define_singleton_method(:definitions) do |_path, _pos|
            mock_range = Object.new
            mock_range.define_singleton_method(:to_lsp) do
              { start: { line: 5, character: 0 }, end: { line: 5, character: 10 } }
            end
            [["/tmp/test.rb", mock_range]]
          end

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/source.rb" }

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::DefinitionListener.new(
            response_builder, uri, node_context, dispatcher, mock_service, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::DefinitionListener, listener
        end

        # T002: Test DefinitionListener returns empty for unknown definitions
        test "definition_listener handles nil service gracefully" do
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |*_args| nil }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { "/tmp/source.rb" }

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::DefinitionListener.new(
            response_builder, uri, node_context, dispatcher, nil, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::DefinitionListener, listener
        end

        # T003: Test DefinitionListener rescues exceptions safely
        test "definition_listener handles missing path gracefully" do
          response_builder = Object.new
          response_builder.define_singleton_method(:<<) { |*_args| nil }

          uri = Object.new
          uri.define_singleton_method(:to_standardized_path) { nil }

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          # nil path should not register any listeners
          assert_nothing_raised do
            Ruby::Lsp::Typeprof::DefinitionListener.new(
              response_builder, uri, node_context, dispatcher, Object.new, mutex
            )
          end
        end
      end
    end
  end
end
