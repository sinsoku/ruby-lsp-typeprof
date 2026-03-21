# frozen_string_literal: true

module Ruby
  module Lsp
    module Typeprof
      class HoverListener
        def initialize(response_builder, node_context, dispatcher, service, mutex)
          @response_builder = response_builder
          @node_context = node_context
          @service = service
          @mutex = mutex
          @path = extract_path(node_context)

          return unless @service

          dispatcher.register(
            self,
            :on_call_node_enter,
            :on_constant_read_node_enter,
            :on_instance_variable_read_node_enter,
            :on_class_variable_read_node_enter,
            :on_global_variable_read_node_enter,
            :on_local_variable_read_node_enter
          )
        end

        def on_call_node_enter(node)
          handle_hover(node)
        end

        def on_constant_read_node_enter(node)
          handle_hover(node)
        end

        def on_instance_variable_read_node_enter(node)
          handle_hover(node)
        end

        def on_class_variable_read_node_enter(node)
          handle_hover(node)
        end

        def on_global_variable_read_node_enter(node)
          handle_hover(node)
        end

        def on_local_variable_read_node_enter(node)
          handle_hover(node)
        end

        private

        def handle_hover(node)
          return unless @service && @path

          location = node.location
          pos = TypeProf::CodePosition.new(location.start_line, location.start_column)

          result = @mutex.synchronize do
            @service.hover(@path, pos)
          end

          return unless result
          return if result.start_with?("???")

          @response_builder.push(
            "**TypeProf**: `#{result}`",
            category: :documentation
          )
        rescue StandardError => e
          warn "ruby-lsp-typeprof: Hover error: #{e.message}"
        end

        def extract_path(node_context)
          node = node_context.node
          return unless node

          source = node.location&.source
          source&.source&.name
        end
      end
    end
  end
end
