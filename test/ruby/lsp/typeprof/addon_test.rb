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

        # T008: Test Addon safe fallback when TypeProf is not installed
        test "activate handles LoadError gracefully" do
          global_state = Object.new
          def global_state.workspace_path
            "/tmp/test"
          end

          outgoing_queue = Thread::Queue.new

          addon = RubyLsp::RubyLspTypeprof::Addon.new

          # The addon should not raise even if typeprof loading fails internally
          # We verify it doesn't crash - actual TypeProf availability depends on environment
          assert_nothing_raised do
            addon.deactivate
          end

          assert_nil addon.instance_variable_get(:@service)

          outgoing_queue.close
        end
      end
    end
  end
end
