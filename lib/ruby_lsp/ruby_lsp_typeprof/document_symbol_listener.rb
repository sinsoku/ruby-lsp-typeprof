# frozen_string_literal: true

require_relative "signature_cache"

module RubyLsp
  module Typeprof
    # Appends the inferred method signature as a child symbol of each method
    # definition symbol produced by Ruby LSP's own DocumentSymbol listener.
    #
    # Ruby LSP does not pass the document URI to `create_document_symbol_listener`,
    # so the URI is read from the core listener already registered on the dispatcher.
    class DocumentSymbolListener
      def initialize(response_builder, dispatcher, service, mutex, outgoing_queue)
        @response_builder = response_builder
        path = document_path(dispatcher)
        @signatures = SignatureCache.new(service, mutex, path, outgoing_queue, feature: "document symbol")

        dispatcher.register(self, :on_def_node_enter) unless @signatures.empty?
      end

      def on_def_node_enter(node)
        hint = @signatures[node.location.start_line]
        return unless hint

        parent = @response_builder.last
        return unless parent.is_a?(LanguageServer::Protocol::Interface::DocumentSymbol)

        parent.children << build_signature_symbol(node, hint)
      end

      private

      def document_path(dispatcher)
        core_listener = dispatcher.listeners.each_value.flat_map(&:itself).find do |listener|
          listener.is_a?(::RubyLsp::Listeners::DocumentSymbol)
        end
        core_listener&.instance_variable_get(:@uri)&.to_standardized_path
      end

      def build_signature_symbol(node, hint)
        range = range_from_location(node.name_loc)

        LanguageServer::Protocol::Interface::DocumentSymbol.new(
          name: hint,
          kind: ::RubyLsp::Constant::SymbolKind::TYPE_PARAMETER,
          range: range,
          selection_range: range
        )
      end

      def range_from_location(location)
        LanguageServer::Protocol::Interface::Range.new(
          start: LanguageServer::Protocol::Interface::Position.new(
            line: location.start_line - 1, character: location.start_column
          ),
          end: LanguageServer::Protocol::Interface::Position.new(
            line: location.end_line - 1, character: location.end_column
          )
        )
      end
    end
  end
end
