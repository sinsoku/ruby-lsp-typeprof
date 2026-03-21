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
          return unless @service

          location = node.location
          pos = TypeProf::CodePosition.new(location.start_line, location.start_column)

          result = try_hover_all_files(pos)

          return unless result
          return if result.start_with?("???")

          @response_builder.push(
            "**TypeProf**: `#{result}`",
            category: :documentation
          )
        rescue StandardError => e
          warn "ruby-lsp-typeprof: Hover error: #{e.message}"
        end

        def try_hover_all_files(pos)
          @mutex.synchronize do
            # TypeProf::Core::Service stores analyzed files in @rb_text_nodes
            paths = @service.instance_variable_get(:@rb_text_nodes).keys
            paths.each do |path|
              result = @service.hover(path, pos)
              return result if result && !result.start_with?("???")
            rescue StandardError
              next
            end
            nil
          end
        end
      end
    end
  end
end
