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
require_relative "typeprof/definition_listener"
require_relative "typeprof/code_lens_listener"
require_relative "typeprof/completion_listener"
