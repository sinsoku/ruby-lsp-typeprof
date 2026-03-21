# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby/lsp/typeprof"

module RubyLsp
  module RubyLspTypeprof
    class Addon < ::RubyLsp::Addon
      def initialize
        super
        @service = nil
        @mutex = Mutex.new
        @outgoing_queue = nil
      end

      def activate(global_state, outgoing_queue)
        @outgoing_queue = outgoing_queue

        require "typeprof"

        @mutex.synchronize do
          @service = TypeProf::Core::Service.new({})
          workspace_path = global_state.workspace_path
          @service.add_workspace(workspace_path, workspace_path)
        end
      rescue LoadError
        warn "ruby-lsp-typeprof: TypeProf is not installed. Addon disabled."
        @service = nil
      rescue StandardError => e
        warn "ruby-lsp-typeprof: Failed to activate: #{e.message}"
        @service = nil
      end

      def deactivate
        @service = nil
      end

      def name
        "TypeProf"
      end

      def version
        Ruby::Lsp::Typeprof::VERSION
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        return unless @service

        Ruby::Lsp::Typeprof::HoverListener.new(response_builder, node_context, dispatcher, @service, @mutex)
      end

      def workspace_did_change_watched_files(changes)
        return unless @service

        send_status_notification("TypeProf: analyzing...")

        @mutex.synchronize do
          changes.each do |change|
            uri = change[:uri]
            path = URI(uri).path
            next unless path&.end_with?(".rb", ".rbs")

            @service.update_file(path, nil)
          rescue StandardError => e
            warn "ruby-lsp-typeprof: Failed to update file #{path}: #{e.message}"
          end
        end

        send_status_notification("TypeProf: ready")
      end

      private

      def send_status_notification(message)
        return unless @outgoing_queue

        @outgoing_queue << {
          method: "window/showMessage",
          params: { type: 3, message: message }
        }
      rescue StandardError
        # Silently ignore notification failures
      end
    end
  end
end
