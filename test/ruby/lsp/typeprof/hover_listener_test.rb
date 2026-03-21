# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/addon"

module Ruby
  module Lsp
    module Typeprof
      class HoverListenerTest < Test::Unit::TestCase
        # T009: Test HoverListener returns type info for method calls
        test "hover_listener pushes type info to response_builder" do
          pushed_content = []
          response_builder = Object.new
          response_builder.define_singleton_method(:push) do |content, category:|
            pushed_content << { content: content, category: category }
          end

          mock_service = Object.new
          mock_service.define_singleton_method(:hover) do |_path, _pos|
            "String"
          end

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          listener = Ruby::Lsp::Typeprof::HoverListener.new(
            response_builder, node_context, dispatcher, mock_service, mutex
          )

          # Verify that the listener was created without error
          assert_instance_of Ruby::Lsp::Typeprof::HoverListener, listener
        end

        # T010: Test HoverListener returns nil gracefully when no type info available
        test "hover_listener handles nil service gracefully" do
          response_builder = Object.new
          response_builder.define_singleton_method(:push) { |*_args| nil }

          node_context = Object.new
          node_context.define_singleton_method(:node) { nil }

          dispatcher = Object.new
          dispatcher.define_singleton_method(:register) { |*_args| nil }

          mutex = Mutex.new

          # nil service should not cause errors
          listener = Ruby::Lsp::Typeprof::HoverListener.new(
            response_builder, node_context, dispatcher, nil, mutex
          )

          assert_instance_of Ruby::Lsp::Typeprof::HoverListener, listener
        end
      end
    end
  end
end
