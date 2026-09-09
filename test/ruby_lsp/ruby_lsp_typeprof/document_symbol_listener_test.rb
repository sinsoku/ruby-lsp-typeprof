# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Typeprof
    class DocumentSymbolListenerTest < Test::Unit::TestCase
      def setup
        @outgoing_queue = Thread::Queue.new
      end

      def teardown
        @outgoing_queue.close
      end

      test "reads the document uri from the core listener and registers on def nodes" do
        service = stub
        service.expects(:code_lens).with("/tmp/test.rb").yields([stub(lineno: 1)], "() -> nil")
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))

        listener = DocumentSymbolListener.new(stub, dispatcher, service, Mutex.new, @outgoing_queue)

        assert_includes dispatcher.listeners[:on_def_node_enter], listener
      end

      test "does nothing when the core listener is not registered" do
        service = stub
        service.expects(:code_lens).never
        dispatcher = Prism::Dispatcher.new

        DocumentSymbolListener.new(stub, dispatcher, service, Mutex.new, @outgoing_queue)

        assert_empty dispatcher.listeners
        assert @outgoing_queue.empty?
      end

      test "does not register when no signatures were inferred" do
        service = stub(code_lens: nil)
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))

        DocumentSymbolListener.new(stub, dispatcher, service, Mutex.new, @outgoing_queue)

        assert_equal 1, dispatcher.listeners[:on_def_node_enter].size
      end

      test "rescues service exceptions and logs them to outgoing_queue" do
        service = stub
        service.stubs(:code_lens).raises("something went wrong")
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))

        DocumentSymbolListener.new(stub, dispatcher, service, Mutex.new, @outgoing_queue)

        notification = @outgoing_queue.pop
        assert_equal "window/logMessage", notification.method
        assert_match(/Ruby LSP TypeProf failed to compute document symbol/, notification.params.message)
        assert_match(/something went wrong/, notification.params.message)
        assert_equal ::RubyLsp::Constant::MessageType::ERROR, notification.params.type
      end

      test "appends the signature as a child symbol of the current method symbol" do
        service = stub
        service.stubs(:code_lens).yields([stub(lineno: 1)], "(Integer) -> String")
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))
        method_symbol = LanguageServer::Protocol::Interface::DocumentSymbol.new(
          name: "foo", kind: ::RubyLsp::Constant::SymbolKind::METHOD,
          range: dummy_range, selection_range: dummy_range, children: []
        )
        response_builder = stub(last: method_symbol)
        listener = DocumentSymbolListener.new(response_builder, dispatcher, service, Mutex.new, @outgoing_queue)

        listener.on_def_node_enter(Prism.parse("def foo(x)\n  x.to_s\nend\n").value.statements.body.first)

        child = method_symbol.children.first
        assert_equal "(Integer) -> String", child.name
        assert_equal ::RubyLsp::Constant::SymbolKind::TYPE_PARAMETER, child.kind
        assert_equal({ line: 0, character: 4 }, child.range.start.to_hash)
        assert_equal({ line: 0, character: 7 }, child.range.end.to_hash)
        assert_equal child.range.to_hash, child.selection_range.to_hash
      end

      test "ignores def nodes without an inferred signature" do
        service = stub
        service.stubs(:code_lens).yields([stub(lineno: 99)], "() -> nil")
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))
        response_builder = stub
        response_builder.expects(:last).never
        listener = DocumentSymbolListener.new(response_builder, dispatcher, service, Mutex.new, @outgoing_queue)

        listener.on_def_node_enter(Prism.parse("def foo; end\n").value.statements.body.first)
      end

      test "ignores def nodes when the current symbol is not a DocumentSymbol" do
        service = stub
        service.stubs(:code_lens).yields([stub(lineno: 1)], "() -> nil")
        dispatcher = build_dispatcher(uri: URI("file:///tmp/test.rb"))
        root = ::RubyLsp::ResponseBuilders::DocumentSymbol::SymbolHierarchyRoot.new
        listener = DocumentSymbolListener.new(stub(last: root), dispatcher, service, Mutex.new, @outgoing_queue)

        listener.on_def_node_enter(Prism.parse("def foo; end\n").value.statements.body.first)

        assert_empty root.children
      end

      private

      def build_dispatcher(uri:)
        dispatcher = Prism::Dispatcher.new
        ::RubyLsp::Listeners::DocumentSymbol.new(::RubyLsp::ResponseBuilders::DocumentSymbol.new, uri, dispatcher)
        dispatcher
      end

      def dummy_range
        position = LanguageServer::Protocol::Interface::Position.new(line: 0, character: 0)
        LanguageServer::Protocol::Interface::Range.new(start: position, end: position)
      end
    end
  end
end
