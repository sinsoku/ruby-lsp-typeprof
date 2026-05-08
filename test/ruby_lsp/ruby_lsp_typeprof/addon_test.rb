# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class AddonTest < Test::Unit::TestCase
      include CaptureStderr

      def setup
        @addon = Addon.new
      end

      test "addon has correct name" do
        assert_equal "TypeProf", @addon.name
      end

      test "addon has correct version" do
        assert_equal VERSION, @addon.version
      end

      test "deactivate clears service" do
        @addon.deactivate
        assert_nil @addon.instance_variable_get(:@service)
      end

      test "workspace_did_change_watched_files ignores non-ruby files" do
        updated_paths = []
        mock_service = stub(:update_file)
        mock_service.stubs(:update_file).with { |path, _code| updated_paths << path }

        addon = Addon.new
        addon.instance_variable_set(:@service, mock_service)

        changes = [
          { uri: "file:///tmp/test.txt", type: 2 },
          { uri: "file:///tmp/test.rb", type: 2 }
        ]
        addon.workspace_did_change_watched_files(changes)

        assert_equal ["/tmp/test.rb"], updated_paths
      end

      test "workspace_did_change_watched_files handles exceptions safely" do
        mock_service = stub(:update_file)
        mock_service.stubs(:update_file).raises("update error")

        addon = Addon.new
        addon.instance_variable_set(:@service, mock_service)

        output = capture_stderr do
          addon.workspace_did_change_watched_files([{ uri: "file:///tmp/test.rb", type: 2 }])
        end

        assert_match(/Failed to update file/, output)
      end

      test "activate skips service initialization when enabled is false" do
        global_state = stub
        global_state.stubs(:settings_for_addon).with("TypeProf").returns({ enabled: false })

        output = capture_stderr { @addon.activate(global_state, stub) }

        assert_nil @addon.instance_variable_get(:@service)
        assert_equal false, @addon.instance_variable_get(:@enabled)
        assert_empty output
      end

      test "create_code_lens_listener returns nil when addon is disabled" do
        addon = Addon.new
        addon.instance_variable_set(:@enabled, false)

        result = addon.create_code_lens_listener(stub, URI("file:///tmp/test.rb"), stub)
        assert_nil result
      end

      test "workspace_did_change_watched_files is no-op when addon is disabled" do
        addon = Addon.new
        addon.instance_variable_set(:@enabled, false)

        assert_nothing_raised do
          addon.workspace_did_change_watched_files([{ uri: "file:///tmp/test.rb", type: 2 }])
        end
      end

      test "create_code_lens_listener returns nil when code lens is disabled" do
        addon = Addon.new
        addon.instance_variable_set(:@service, stub)
        addon.instance_variable_set(:@code_lens_enabled, false)

        result = addon.create_code_lens_listener(stub, URI("file:///tmp/test.rb"), stub)
        assert_nil result
      end

      test "create_code_lens_listener returns a listener when code lens is enabled" do
        service = stub
        service.stubs(:code_lens)

        addon = Addon.new
        addon.instance_variable_set(:@service, service)
        addon.instance_variable_set(:@code_lens_enabled, true)

        dispatcher = stub
        dispatcher.stubs(:register)

        listener = addon.create_code_lens_listener(stub, URI("file:///tmp/test.rb"), dispatcher)
        assert_kind_of CodeLensListener, listener
      end
    end
  end
end
