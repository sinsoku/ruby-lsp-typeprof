# frozen_string_literal: true

require_relative "typeprof/version"

module Ruby
  module Lsp
    module Typeprof
      class Error < StandardError; end
    end
  end
end

require_relative "typeprof/hover_listener"
