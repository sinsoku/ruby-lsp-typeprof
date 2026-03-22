# frozen_string_literal: true

module Ruby
  module Lsp
    module Typeprof
      class DefinitionListener
        def initialize(response_builder, uri, _node_context, dispatcher, service, mutex) # rubocop:disable Metrics/ParameterLists
          @response_builder = response_builder
          @path = uri.to_standardized_path
          @service = service
          @mutex = mutex

          return unless @service && @path

          dispatcher.register(
            self,
            :on_call_node_enter,
            :on_constant_read_node_enter,
            :on_constant_path_node_enter
          )
        end

        def on_call_node_enter(node)
          handle_definition(node)
        end

        def on_constant_read_node_enter(node)
          handle_definition(node)
        end

        def on_constant_path_node_enter(node)
          handle_definition(node)
        end

        private

        def handle_definition(node)
          return unless @service && @path

          location = node.location
          pos = TypeProf::CodePosition.new(location.start_line, location.start_column)

          defs = @mutex.synchronize do
            @service.definitions(@path, pos)
          end

          return unless defs && !defs.empty?

          defs.each { |def_path, code_range| push_location(def_path, code_range) }
        rescue StandardError => e
          warn "ruby-lsp-typeprof: Definition error: #{e.message}"
        end

        def push_location(def_path, code_range)
          range = code_range.to_lsp
          @response_builder << Interface::Location.new(
            uri: "file://#{def_path}",
            range: Interface::Range.new(
              start: Interface::Position.new(line: range[:start][:line], character: range[:start][:character]),
              end: Interface::Position.new(line: range[:end][:line], character: range[:end][:character])
            )
          )
        end
      end
    end
  end
end
