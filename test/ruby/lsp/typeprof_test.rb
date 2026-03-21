# frozen_string_literal: true

require "test_helper"

module Ruby
  module Lsp
    class TypeprofTest < Test::Unit::TestCase
      test "VERSION" do
        assert do
          ::Ruby::Lsp::Typeprof.const_defined?(:VERSION)
        end
      end

      test "Error class is defined" do
        assert do
          ::Ruby::Lsp::Typeprof.const_defined?(:Error)
        end
      end
    end
  end
end
