# frozen_string_literal: true

require "uri"
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
        @diagnostic_severity = :error
      end

      def activate(global_state, outgoing_queue)
        @outgoing_queue = outgoing_queue
        require "typeprof"

        @service = initialize_service(global_state.workspace_path)
        publish_diagnostics_for_all_files if @service
      rescue LoadError
        warn "ruby-lsp-typeprof: TypeProf is not installed. Addon disabled."
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

      def create_completion_listener(response_builder, node_context, dispatcher, uri)
        return unless @service

        Ruby::Lsp::Typeprof::CompletionListener.new(response_builder, node_context, dispatcher, uri, @service, @mutex)
      end

      def create_code_lens_listener(response_builder, uri, dispatcher)
        return unless @service

        Ruby::Lsp::Typeprof::CodeLensListener.new(response_builder, uri, dispatcher, @service, @mutex)
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        return unless @service

        Ruby::Lsp::Typeprof::DefinitionListener.new(response_builder, uri, node_context, dispatcher, @service, @mutex)
      end

      def workspace_did_change_watched_files(changes)
        return unless @service

        send_status_notification("TypeProf: analyzing...")

        @mutex.synchronize do
          changes.each do |change|
            uri = change[:uri]
            path = URI.parse(uri).path
            next unless path&.end_with?(".rb", ".rbs")

            @service.update_file(path, nil)
            publish_diagnostics(uri.to_s, path)
          rescue StandardError => e
            warn "ruby-lsp-typeprof: Failed to update file #{path}: #{e.message}"
          end
        end

        send_status_notification("TypeProf: ready")
      end

      private

      def initialize_service(workspace_path)
        conf = load_typeprof_conf(workspace_path)

        unless conf
          warn "ruby-lsp-typeprof: typeprof.conf.json(c) not found in #{workspace_path}. Addon disabled."
          return
        end

        options = {}
        options[:exclude_patterns] = conf[:exclude] if conf[:exclude]
        rbs_dir = File.expand_path(conf[:rbs_dir] || "sig", workspace_path)

        if conf[:diagnostic_severity]
          severity = conf[:diagnostic_severity].to_sym
          @diagnostic_severity = severity if %i[error warning info hint].include?(severity)
        end

        @mutex.synchronize do
          service = nil
          (conf[:analysis_unit_dirs] || ["lib"]).each do |dir|
            dir = File.expand_path(dir, workspace_path)
            service = TypeProf::Core::Service.new(options)
            service.add_workspace(dir, rbs_dir)
          end
          service
        end
      end

      def publish_diagnostics_for_all_files
        @mutex.synchronize do
          paths = @service.instance_variable_get(:@rb_text_nodes).keys
          paths.each do |path|
            uri = "file://#{path}"
            publish_diagnostics(uri, path)
          rescue StandardError => e
            warn "ruby-lsp-typeprof: Failed to publish initial diagnostics for #{path}: #{e.message}"
          end
        end
      end

      def publish_diagnostics(uri, path)
        diagnostics = []
        @service.diagnostics(path) do |diag|
          diagnostics << diag.to_lsp(severity: @diagnostic_severity)
        end

        send_diagnostics_notification(uri, diagnostics)
      rescue StandardError => e
        warn "ruby-lsp-typeprof: Failed to publish diagnostics: #{e.message}"
        send_diagnostics_notification(uri, [])
      end

      def send_diagnostics_notification(uri, diagnostics)
        return unless @outgoing_queue

        @outgoing_queue << {
          method: "textDocument/publishDiagnostics",
          params: { uri: uri, diagnostics: diagnostics }
        }
      rescue StandardError
        # Silently ignore notification failures
      end

      def send_status_notification(message)
        return unless @outgoing_queue

        @outgoing_queue << {
          method: "window/showMessage",
          params: { type: 3, message: message }
        }
      rescue StandardError
        # Silently ignore notification failures
      end

      def load_typeprof_conf(workspace_path)
        conf_path = [".json", ".jsonc"].filter_map do |ext|
          path = File.join(workspace_path, "typeprof.conf#{ext}")
          path if File.readable?(path)
        end.first

        return unless conf_path

        TypeProf::LSP.load_json_with_comments(conf_path, symbolize_names: true)
      end
    end
  end
end
