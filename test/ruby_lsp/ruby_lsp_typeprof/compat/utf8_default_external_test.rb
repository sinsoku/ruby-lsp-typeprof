# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/compat/utf8_default_external"

module RubyLsp
  module Typeprof
    module Compat
      class Utf8DefaultExternalTest < Test::Unit::TestCase
        include EncodingTestHelper

        def setup
          @addon = Addon.new.extend(Utf8DefaultExternal)
        end

        test "build_service runs with UTF-8 default_external" do
          encodings = []
          Addon.any_instance.stubs(:build_service)
               .with { |_path| encodings << Encoding.default_external }
               .returns(:service)

          with_default_external(Encoding::US_ASCII) do
            assert_equal :service, @addon.send(:build_service, "/tmp")
            assert_equal Encoding::US_ASCII, Encoding.default_external
          end

          assert_equal [Encoding::UTF_8], encodings
        end

        test "build_service restores default_external when it raises" do
          Addon.any_instance.stubs(:build_service).raises("boom")

          with_default_external(Encoding::US_ASCII) do
            assert_raise_message("boom") { @addon.send(:build_service, "/tmp") }
            assert_equal Encoding::US_ASCII, Encoding.default_external
          end
        end

        test "workspace_did_change_watched_files updates files with UTF-8 default_external" do
          encodings = []
          mock_service = stub(:update_file)
          mock_service.stubs(:update_file).with { |_path, _code| encodings << Encoding.default_external }
          @addon.instance_variable_set(:@service, mock_service)

          with_default_external(Encoding::US_ASCII) do
            @addon.workspace_did_change_watched_files([{ uri: "file:///tmp/test.rbs", type: 2 }])
            assert_equal Encoding::US_ASCII, Encoding.default_external
          end

          assert_equal [Encoding::UTF_8], encodings
        end

        test "is still needed for the supported TypeProf versions" do
          spec = Gem.loaded_specs.fetch("ruby-lsp-typeprof")
          dependency = spec.runtime_dependencies.find { |dep| dep.name == "typeprof" }

          assert_true dependency.requirement.satisfied_by?(Gem::Version.new("0.33.1")),
                      "TypeProf < 0.33.2 is no longer supported. Remove Compat::Utf8DefaultExternal."
        end
      end
    end
  end
end
