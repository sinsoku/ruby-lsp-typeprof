# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ruby_lsp/ruby_lsp_typeprof/addon"
require "language_server-protocol"
require "ruby_lsp/internal"
require "ruby_lsp/test_helper"
require "tmpdir"
require "fileutils"

require "test-unit"
require "mocha/test_unit"

module IntegrationTestHelper
  include RubyLsp::TestHelper

  private

  def generate_code_lens_for_source(source, workspace_path: nil)
    Dir.mktmpdir do |tmpdir|
      workspace = workspace_path || tmpdir
      uri = write_source_file(workspace, source)

      with_server(source, uri, load_addons: false) do |server, _uri|
        setup_workspace_and_addons(server, workspace)
        request_code_lens(server, uri)
      end
    end
  end

  def write_source_file(workspace, source)
    FileUtils.mkdir_p(workspace)
    file_path = File.join(workspace, "test.rb")
    File.write(file_path, source)
    URI("file://#{file_path}")
  end

  def setup_workspace_and_addons(server, workspace)
    server.global_state.instance_variable_set(
      :@workspace_uri,
      URI::Generic.from_path(path: workspace)
    )
    server.load_addons(include_project_addons: false)
  end

  def request_code_lens(server, uri)
    server.process_message(
      method: "textDocument/codeLens",
      id: 1,
      params: { textDocument: { uri: uri.to_s } }
    )
    pop_result(server).response
  end
end
