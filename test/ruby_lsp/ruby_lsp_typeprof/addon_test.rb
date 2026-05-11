# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class AddonTest < Test::Unit::TestCase
      def setup
        @addon = Addon.new
        @outgoing_queue = Thread::Queue.new
      end

      def teardown
        @outgoing_queue.close
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

      test "workspace_did_change_watched_files logs exceptions to outgoing_queue" do
        mock_service = stub(:update_file)
        mock_service.stubs(:update_file).raises("update error")

        addon = Addon.new
        addon.instance_variable_set(:@service, mock_service)
        addon.instance_variable_set(:@outgoing_queue, @outgoing_queue)

        addon.workspace_did_change_watched_files([{ uri: "file:///tmp/test.rb", type: 2 }])

        notification = @outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(/Ruby LSP TypeProf failed to update file/, notification.params.message)
        assert_equal ::RubyLsp::Constant::MessageType::ERROR, notification.params.type
      end

      test "activate logs an activation message" do
        global_state = stub
        global_state.stubs(:settings_for_addon).with("TypeProf").returns({ enabled: false })

        @addon.activate(global_state, @outgoing_queue)

        notification = @outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(/Activating Ruby LSP TypeProf add-on v#{Regexp.escape(VERSION)}/o, notification.params.message)
      end

      test "activate skips service initialization when enabled is false" do
        global_state = stub
        global_state.stubs(:settings_for_addon).with("TypeProf").returns({ enabled: false })

        @addon.activate(global_state, @outgoing_queue)

        assert_nil @addon.instance_variable_get(:@service)
        assert_equal false, @addon.instance_variable_get(:@enabled)
      end

      test "activate logs an error notification when activation fails" do
        global_state = stub
        global_state.stubs(:settings_for_addon).with("TypeProf").returns({})
        global_state.stubs(:workspace_path).raises("boom")

        @addon.activate(global_state, @outgoing_queue)

        _activation_log = @outgoing_queue.pop
        notification = @outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(/Ruby LSP TypeProf failed to activate/, notification.params.message)
        assert_equal ::RubyLsp::Constant::MessageType::ERROR, notification.params.type
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
