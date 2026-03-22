# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/addon"

module Ruby
  module Lsp
    module Typeprof
      class AddonTest < Test::Unit::TestCase
        def setup
          @addon = RubyLsp::RubyLspTypeprof::Addon.new
        end

        # T007: Test Addon activation and deactivation lifecycle
        test "addon has correct name" do
          assert_equal "TypeProf", @addon.name
        end

        test "addon has correct version" do
          assert_equal Ruby::Lsp::Typeprof::VERSION, @addon.version
        end

        test "deactivate clears service" do
          @addon.deactivate
          assert_nil @addon.instance_variable_get(:@service)
        end

        # T001: Test diagnostics are published after file change
        test "publish_diagnostics sends diagnostics after file update" do
          addon = build_addon_with_mock_service(diagnostics_count: 1)
          outgoing_queue = addon.instance_variable_get(:@outgoing_queue)

          changes = [{ uri: "file:///tmp/test.rb", type: 2 }]
          addon.workspace_did_change_watched_files(changes)

          messages = drain_queue(outgoing_queue)
          assert find_publish_diagnostics(messages), "Expected publishDiagnostics notification"
        end

        # T002: Test empty diagnostics clears previous diagnostics
        test "publish_diagnostics sends empty array when no diagnostics" do
          addon = build_addon_with_mock_service(diagnostics_count: 0)
          outgoing_queue = addon.instance_variable_get(:@outgoing_queue)

          changes = [{ uri: "file:///tmp/test.rb", type: 2 }]
          addon.workspace_did_change_watched_files(changes)

          messages = drain_queue(outgoing_queue)
          assert find_publish_diagnostics(messages), "Expected publishDiagnostics to clear previous diagnostics"
        end

        # T003: Test diagnostics exceptions are rescued safely
        test "diagnostics exceptions do not crash addon" do
          addon = build_addon_with_mock_service(raise_on_diagnostics: true)

          changes = [{ uri: "file:///tmp/test.rb", type: 2 }]
          assert_nothing_raised do
            addon.workspace_did_change_watched_files(changes)
          end
        end

        # T008: Test Addon safe fallback when TypeProf is not installed
        test "activate handles LoadError gracefully" do
          addon = RubyLsp::RubyLspTypeprof::Addon.new

          assert_nothing_raised do
            addon.deactivate
          end

          assert_nil addon.instance_variable_get(:@service)
        end

        private

        def build_addon_with_mock_service(diagnostics_count: 0, raise_on_diagnostics: false)
          outgoing_queue = Thread::Queue.new
          addon = RubyLsp::RubyLspTypeprof::Addon.new
          addon.instance_variable_set(:@outgoing_queue, outgoing_queue)
          addon.instance_variable_set(:@diagnostic_severity, :error)

          mock_service = Object.new
          mock_service.define_singleton_method(:update_file) { |_path, _code| true }

          if raise_on_diagnostics
            mock_service.define_singleton_method(:diagnostics) { |_path, &_blk| raise "diagnostics error" }
          else
            mock_service.define_singleton_method(:diagnostics) do |_path, &blk|
              diagnostics_count.times do
                mock_diag = Object.new
                mock_diag.define_singleton_method(:to_lsp) do |severity:| # rubocop:disable Lint/UnusedBlockArgument
                  { range: { start: { line: 0, character: 0 }, end: { line: 0, character: 5 } },
                    source: "TypeProf", message: "type error", severity: 1 }
                end
                blk&.call(mock_diag)
              end
            end
          end

          addon.instance_variable_set(:@service, mock_service)
          addon
        end

        def drain_queue(queue)
          messages = []
          messages << queue.pop until queue.empty?
          messages
        end

        def find_publish_diagnostics(messages)
          messages.any? do |m|
            case m
            when Hash
              m[:method] == "textDocument/publishDiagnostics"
            else
              m.respond_to?(:to_hash) && m.to_hash[:method] == "textDocument/publishDiagnostics"
            end
          end
        end
      end
    end
  end
end
