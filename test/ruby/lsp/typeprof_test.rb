# frozen_string_literal: true

require "test_helper"

class Ruby::Lsp::TypeprofTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::Ruby::Lsp::Typeprof.const_defined?(:VERSION)
    end
  end

  test "something useful" do
    assert_equal("expected", "actual")
  end
end
