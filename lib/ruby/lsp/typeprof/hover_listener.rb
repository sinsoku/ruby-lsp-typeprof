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
          @path = find_path_from_node(node_context, service)

          return unless @service && @path

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

        def find_path_from_node(node_context, service)
          node = node_context.node
          return unless node

          source_lines = node.location.source_lines
          return if source_lines.empty?

          source_text = source_lines.join

          paths = service.instance_variable_get(:@rb_text_nodes).keys
          paths.find do |path|
            File.readable?(path) && File.read(path) == source_text
          end
        rescue StandardError
          nil
        end
      end
    end
  end
end
