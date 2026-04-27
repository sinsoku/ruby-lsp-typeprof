# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class IntegrationTest < Test::Unit::TestCase
      include IntegrationTestHelper

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
            capture_stderr do
              setup_workspace_and_addons(server, bad_workspace)
            end
            response = request_code_lens(server, uri)

            assert_empty response
          end
        end
      end
    end
  end
end
