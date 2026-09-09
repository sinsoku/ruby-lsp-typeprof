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

module EncodingTestHelper
  private

  # Ruby warns on assigning Encoding.default_external under -w, so silence
  # $VERBOSE while switching it.
  def with_default_external(encoding)
    orig = Encoding.default_external
    silently { Encoding.default_external = encoding }
    yield
  ensure
    silently { Encoding.default_external = orig }
  end

  def silently
    verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = verbose
  end

  def write_non_ascii_workspace(dir)
    sig_dir = File.join(dir, "sig")
    FileUtils.mkdir_p(sig_dir)
    File.write(File.join(sig_dir, "foo.rbs"), "# 日本語コメント\nclass Foo\n  def bar: () -> String\nend\n", encoding: "UTF-8")
    File.write(File.join(dir, "typeprof.conf.jsonc"), <<~JSONC, encoding: "UTF-8")
      {
        // 日本語コメント
        "rbs_dir": "sig/",
        "analysis_unit_dirs": ["."]
      }
    JSONC
  end
end

module IntegrationTestHelper
  include RubyLsp::TestHelper

  private

  def generate_code_lens_for_source(source, workspace_path: nil)
    with_addon_server(source, workspace_path: workspace_path) do |server, uri|
      request_code_lens(server, uri)
    end
  end

  def generate_document_symbol_for_source(source, workspace_path: nil)
    with_addon_server(source, workspace_path: workspace_path) do |server, uri|
      request_document_symbol(server, uri)
    end
  end

  def with_addon_server(source, workspace_path: nil)
    Dir.mktmpdir do |tmpdir|
      workspace = workspace_path || tmpdir
      uri = write_source_file(workspace, source)

      with_server(source, uri, load_addons: false) do |server, _uri|
        setup_workspace_and_addons(server, workspace)
        yield server, uri
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
    request(server, "textDocument/codeLens", uri)
  end

  def request_document_symbol(server, uri)
    request(server, "textDocument/documentSymbol", uri)
  end

  def request(server, method, uri)
    server.process_message(
      method: method,
      id: 1,
      params: { textDocument: { uri: uri.to_s } }
    )
    pop_result(server).response
  end
end
