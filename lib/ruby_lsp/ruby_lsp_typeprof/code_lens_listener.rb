# frozen_string_literal: true

require_relative "signature_cache"

module RubyLsp
  module Typeprof
    class CodeLensListener
      def initialize(response_builder, uri, dispatcher, service, mutex, outgoing_queue)
        @response_builder = response_builder
        @signatures = SignatureCache.new(service, mutex, uri.to_standardized_path, outgoing_queue, feature: "code lens")

        dispatcher.register(self, :on_def_node_enter) unless @signatures.empty?
      end

      def on_def_node_enter(node)
        line = node.location.start_line
        hint = @signatures[line]
        return unless hint

        @response_builder << build_code_lens(line, hint)
      end

      private

      def build_code_lens(line, hint)
        position = LanguageServer::Protocol::Interface::Position.new(line: line - 1, character: 0)

        LanguageServer::Protocol::Interface::CodeLens.new(
          range: LanguageServer::Protocol::Interface::Range.new(start: position, end: position),
          command: LanguageServer::Protocol::Interface::Command.new(title: "#: #{hint}", command: "")
        )
      end
    end
  end
end
