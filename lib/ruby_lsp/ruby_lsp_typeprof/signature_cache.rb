# frozen_string_literal: true

require_relative "loggable"

module RubyLsp
  module Typeprof
    # Collects the method signatures TypeProf inferred for a single file,
    # keyed by the 1-based line number of the method definition.
    class SignatureCache
      include Loggable

      def initialize(service, mutex, path, outgoing_queue, feature:)
        @outgoing_queue = outgoing_queue
        @hints = {}
        return unless path

        mutex.synchronize do
          service.code_lens(path) do |code_range, hint|
            @hints[code_range.first.lineno] = hint
          end
        end
      rescue StandardError => e
        log_error("Ruby LSP TypeProf failed to compute #{feature} for #{path}: #{e.full_message(highlight: false)}")
      end

      def [](line)
        @hints[line]
      end

      def empty?
        @hints.empty?
      end
    end
  end
end
