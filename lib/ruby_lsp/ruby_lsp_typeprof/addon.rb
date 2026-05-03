# frozen_string_literal: true

require "ruby-lsp-typeprof"
require "ruby_lsp/addon"
require "uri"

require_relative "code_lens_listener"

module RubyLsp
  module Typeprof
    class Addon < ::RubyLsp::Addon
      def initialize
        super
        @service = nil
        @mutex = Mutex.new
        @code_lens_enabled = true
      end

      def activate(global_state, _outgoing_queue)
        require "typeprof"

        settings = global_state.settings_for_addon(name)
        @code_lens_enabled = settings&.dig(:enableCodeLens) != false
        @service = build_service(global_state.workspace_path)
      rescue StandardError => e
        warn "ruby-lsp-typeprof: Failed to activate: #{e.message}"
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

        CodeLensListener.new(response_builder, uri, dispatcher, @service, @mutex)
      end

      def workspace_did_change_watched_files(changes)
        return unless @service

        @mutex.synchronize do
          changes.each { |change| update_changed_file(change) }
        end
      end

      private

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

        @service.update_file(path, nil)
      rescue StandardError => e
        warn "ruby-lsp-typeprof: Failed to update file #{path}: #{e.message}"
      end
    end
  end
end
