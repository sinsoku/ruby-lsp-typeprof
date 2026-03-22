# frozen_string_literal: true

module Ruby
  module Lsp
    module Typeprof
      class CompletionListener
        def initialize(response_builder, node_context, _dispatcher, uri, service, mutex) # rubocop:disable Metrics/ParameterLists
          @response_builder = response_builder
          @service = service
          @mutex = mutex
          @path = uri.to_standardized_path
          @node_context = node_context

          return unless @service && @path

          fetch_completions
        end

        private

        def fetch_completions
          node = @node_context.node
          return unless node

          location = node.location
          pos = ::TypeProf::CodePosition.new(location.start_line, location.start_column)
          trigger = "."

          @mutex.synchronize do
            @service.completion(@path, trigger, pos) do |mid, signature|
              @response_builder << LanguageServer::Protocol::Interface::CompletionItem.new(
                label: mid.to_s,
                kind: LanguageServer::Protocol::Constant::CompletionItemKind::METHOD,
                detail: signature
              )
            end
          end
        rescue StandardError => e
          warn "ruby-lsp-typeprof: Completion error: #{e.message}"
        end
      end
    end
  end
end
