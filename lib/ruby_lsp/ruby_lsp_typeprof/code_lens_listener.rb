# frozen_string_literal: true

module RubyLsp
  module Typeprof
    class CodeLensListener
      def initialize(response_builder, uri, dispatcher, service, mutex)
        @response_builder = response_builder
        @path = uri.to_standardized_path
        @lens_cache = {}

        cache_code_lens_results(service, mutex)
        dispatcher.register(self, :on_def_node_enter) unless @lens_cache.empty?
      end

      def on_def_node_enter(node)
        line = node.location.start_line
        hint = @lens_cache[line]
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

      def cache_code_lens_results(service, mutex)
        mutex.synchronize do
          service.code_lens(@path) do |code_range, hint|
            @lens_cache[code_range.first.lineno] = hint
          end
        end
      rescue StandardError => e
        warn "ruby-lsp-typeprof: Code lens error: #{e.message}"
      end
    end
  end
end
