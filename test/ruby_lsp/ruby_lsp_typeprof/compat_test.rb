# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_typeprof/compat/utf8_default_external"

module RubyLsp
  module Typeprof
    class CompatTest < Test::Unit::TestCase
      test "apply! extends the addon with Utf8DefaultExternal for TypeProf < 0.33.2" do
        Compat.stubs(:typeprof?).with(">= 0.33.2").returns(false)
        addon = Addon.new

        Compat.apply!(addon)

        assert_true addon.is_a?(Compat::Utf8DefaultExternal)
      end

      test "apply! does nothing for TypeProf >= 0.33.2" do
        Compat.stubs(:typeprof?).with(">= 0.33.2").returns(true)
        addon = Addon.new

        Compat.apply!(addon)

        assert_false addon.is_a?(Compat::Utf8DefaultExternal)
      end

      test "typeprof? checks the TypeProf version against the requirements" do
        require "typeprof/version"
        version = TypeProf::VERSION

        assert_true Compat.typeprof?(">= #{version}", "<= #{version}")
        assert_false Compat.typeprof?(">= #{version}", "< #{version}")
      end
    end
  end
end
