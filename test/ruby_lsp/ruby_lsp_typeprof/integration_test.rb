# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class IntegrationTest < Test::Unit::TestCase
      include IntegrationTestHelper
      include EncodingTestHelper

      def teardown
        RubyLsp::Addon.addons.each(&:deactivate)
        RubyLsp::Addon.addons.clear
      end

      test "code lens returns type signatures for inferred methods" do
        source = <<~RUBY
          def add(x, y)
            x + y
          end

          add(1, 2)
        RUBY

        response = generate_code_lens_for_source(source)

        refute_empty response, "Expected code lens results but got none"

        titles = response.map { |lens| lens.attributes[:command].attributes[:title] }
        assert titles.any? { |t| t.include?("Integer") },
               "Expected a code lens mentioning Integer, got: #{titles.inspect}"
      end

      test "document symbol returns inferred signatures as children of method symbols" do
        source = <<~RUBY
          class Calc
            def add(x, y)
              x + y
            end
          end

          Calc.new.add(1, 2)
        RUBY

        response = generate_document_symbol_for_source(source)

        class_symbol = response.find { |symbol| symbol.name == "Calc" }
        refute_nil class_symbol, "Expected a Calc symbol, got: #{response.map(&:name).inspect}"
        method_symbol = class_symbol.children.find { |symbol| symbol.name == "add" }
        refute_nil method_symbol

        signature = method_symbol.children.find { |symbol| symbol.kind == ::RubyLsp::Constant::SymbolKind::TYPE_PARAMETER }
        refute_nil signature, "Expected a signature child symbol, got: #{method_symbol.children.map(&:name).inspect}"
        assert_equal "(Integer, Integer) -> Integer", signature.name
        assert_equal 1, signature.range.start.line
      end

      test "document symbol does not add signatures for methods annotated with rbs-inline" do
        source = <<~RUBY
          class Calc
            #: (Integer, Integer) -> Integer
            def add(x, y)
              x + y
            end
          end
        RUBY

        response = generate_document_symbol_for_source(source)

        class_symbol = response.find { |symbol| symbol.name == "Calc" }
        method_symbol = class_symbol.children.find { |symbol| symbol.name == "add" }
        assert_empty method_symbol.children
      end

      test "document symbol returns inferred signatures for non-ASCII RBS when default_external is US-ASCII" do
        source = <<~RUBY
          class Foo
            def baz = bar
          end
        RUBY

        Dir.mktmpdir do |workspace|
          write_non_ascii_workspace(workspace)

          response = with_default_external(Encoding::US_ASCII) do
            generate_document_symbol_for_source(source, workspace_path: workspace)
          end

          class_symbol = response.find { |symbol| symbol.name == "Foo" }
          method_symbol = class_symbol.children.find { |symbol| symbol.name == "baz" }
          signature = method_symbol.children.find { |symbol| symbol.kind == ::RubyLsp::Constant::SymbolKind::TYPE_PARAMETER }
          refute_nil signature, "Expected a signature child symbol, got: #{method_symbol.children.map(&:name).inspect}"
          assert_equal "-> String", signature.name
        end
      end

      test "document symbol keeps core symbols when service fails to activate" do
        source = <<~RUBY
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY

        Dir.mktmpdir do |tmpdir|
          bad_workspace = File.join(tmpdir, "nonexistent")
          file_path = File.join(tmpdir, "test.rb")
          File.write(file_path, source)
          uri = URI("file://#{file_path}")

          with_server(source, uri, load_addons: false) do |server, _uri|
            setup_workspace_and_addons(server, bad_workspace)
            response = request_document_symbol(server, uri)

            assert_equal ["greet"], response.map(&:name)
            assert_empty response.first.children
          end
        end
      end

      test "code lens returns empty when service fails to activate" do
        source = <<~RUBY
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY

        Dir.mktmpdir do |tmpdir|
          bad_workspace = File.join(tmpdir, "nonexistent")
          file_path = File.join(tmpdir, "test.rb")
          File.write(file_path, source)
          uri = URI("file://#{file_path}")

          with_server(source, uri, load_addons: false) do |server, _uri|
            setup_workspace_and_addons(server, bad_workspace)
            response = request_code_lens(server, uri)

            assert_empty response
          end
        end
      end
    end
  end
end
