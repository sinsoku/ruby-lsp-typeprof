# frozen_string_literal: true

module RubyLsp
  module Typeprof
    module Loggable
      private

      def log_message(message, type: ::RubyLsp::Constant::MessageType::LOG)
        return if @outgoing_queue.nil? || @outgoing_queue.closed?

        @outgoing_queue << ::RubyLsp::Notification.window_log_message(message, type: type)
      end

      def log_error(message)
        log_message(message, type: ::RubyLsp::Constant::MessageType::ERROR)
      end
    end
  end
end
