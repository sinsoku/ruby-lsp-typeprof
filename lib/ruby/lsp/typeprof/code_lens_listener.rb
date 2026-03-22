# frozen_string_literal: true

module Ruby
  module Lsp
    module Typeprof
      class CodeLensListener
        def initialize(response_builder, uri, dispatcher, service, mutex)
          @response_builder = response_builder
          @service = service
          @mutex = mutex
          @path = uri.to_standardized_path
          @lens_cache = {}

          return unless @service && @path

          cache_code_lens_results
          dispatcher.register(self, :on_def_node_enter) unless @lens_cache.empty?
        end

        def on_def_node_enter(node)
          line = node.location.start_line
          hint = @lens_cache[line]
          return unless hint

          @response_builder << LanguageServer::Protocol::Interface::CodeLens.new(
            range: LanguageServer::Protocol::Interface::Range.new(
              start: LanguageServer::Protocol::Interface::Position.new(line: line - 1, character: 0),
              end: LanguageServer::Protocol::Interface::Position.new(line: line - 1, character: 0)
            ),
            command: LanguageServer::Protocol::Interface::Command.new(
              title: "#: #{hint}",
              command: ""
            )
          )
        end

        private

        def cache_code_lens_results
          @mutex.synchronize do
            @service.code_lens(@path) do |code_range, hint|
              @lens_cache[code_range.first.lineno] = hint
            end
          end
        rescue StandardError => e
          warn "ruby-lsp-typeprof: Code lens error: #{e.message}"
        end
      end
    end
  end
end
