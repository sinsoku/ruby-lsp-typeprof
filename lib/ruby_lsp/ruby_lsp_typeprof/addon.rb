# frozen_string_literal: true

require "ruby-lsp-typeprof"
require "ruby_lsp/addon"
require "uri"

require_relative "code_lens_listener"
require_relative "document_symbol_listener"
require_relative "loggable"

module RubyLsp
  module Typeprof
    class Addon < ::RubyLsp::Addon
      include Loggable

      def initialize
        super
        @service = nil
        @mutex = Mutex.new
        @enabled = true
        @code_lens_enabled = true
        @document_symbol_enabled = true
      end

      def activate(global_state, outgoing_queue)
        @outgoing_queue = outgoing_queue
        log_message("Activating Ruby LSP TypeProf add-on v#{VERSION}")

        load_settings(global_state)
        return unless @enabled

        require "typeprof"
        @service = with_utf8_default_external { build_service(global_state.workspace_path) }
      rescue StandardError => e
        log_error("Ruby LSP TypeProf failed to activate: #{e.full_message(highlight: false)}")
      end

      def deactivate
        @service = nil
      end

      def name
        "TypeProf"
      end

      def version
        VERSION
      end

      def create_code_lens_listener(response_builder, uri, dispatcher)
        return unless @service
        return unless @code_lens_enabled

        CodeLensListener.new(response_builder, uri, dispatcher, @service, @mutex, @outgoing_queue)
      end

      def create_document_symbol_listener(response_builder, dispatcher)
        return unless @service
        return unless @document_symbol_enabled

        DocumentSymbolListener.new(response_builder, dispatcher, @service, @mutex, @outgoing_queue)
      end

      def workspace_did_change_watched_files(changes)
        return unless @service

        @mutex.synchronize do
          changes.each { |change| update_changed_file(change) }
        end
      end

      private

      def load_settings(global_state)
        settings = global_state.settings_for_addon(name)
        @enabled = settings&.dig(:enabled) != false
        @code_lens_enabled = settings&.dig(:enableCodeLens) != false
        @document_symbol_enabled = settings&.dig(:enableDocumentSymbol) != false
      end

      def build_service(workspace_path)
        conf = load_typeprof_conf(workspace_path) || default_conf
        rbs_dir = File.expand_path(conf[:rbs_dir], workspace_path)

        service = TypeProf::Core::Service.new(conf)
        conf[:analysis_unit_dirs].each do |dir|
          service.add_workspace(File.expand_path(dir, workspace_path), rbs_dir)
        end
        service
      end

      def default_conf
        { analysis_unit_dirs: ["."], rbs_dir: "sig/" }
      end

      def load_typeprof_conf(workspace_path)
        conf_path = ["typeprof.conf.json", "typeprof.conf.jsonc"].find do |name|
          File.readable?(File.join(workspace_path, name))
        end
        return unless conf_path

        conf = TypeProf::LSP.load_json_with_comments(File.join(workspace_path, conf_path), symbolize_names: true)
        exclude = conf.delete(:exclude)
        conf[:exclude_patterns] = exclude if exclude
        conf
      end

      def update_changed_file(change)
        path = URI.parse(change[:uri]).path
        return unless path&.end_with?(".rb", ".rbs")

        with_utf8_default_external { @service.update_file(path, nil) }
      rescue StandardError => e
        log_error("Ruby LSP TypeProf failed to update file #{path}: #{e.full_message(highlight: false)}")
      end

      # TypeProf reads files with File.read, which follows Encoding.default_external.
      # Without LANG that is US-ASCII and non-ASCII .rbs files fail to parse.
      # See ruby/typeprof#479.
      def with_utf8_default_external
        orig = Encoding.default_external
        return yield if orig == Encoding::UTF_8

        Encoding.default_external = Encoding::UTF_8
        begin
          yield
        ensure
          Encoding.default_external = orig
        end
      end
    end
  end
end
