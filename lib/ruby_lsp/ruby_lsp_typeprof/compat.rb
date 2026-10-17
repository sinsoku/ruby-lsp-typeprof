# frozen_string_literal: true

module RubyLsp
  module Typeprof
    module Compat
      class << self
        def apply!(addon)
          return if typeprof?(">= 0.33.2")

          require_relative "compat/utf8_default_external"
          addon.extend(Utf8DefaultExternal)
        end

        def typeprof?(*requirements)
          require "typeprof/version"
          satisfies?(TypeProf::VERSION, *requirements)
        end

        private

        def satisfies?(version, *requirements)
          Gem::Requirement.new(*requirements).satisfied_by?(Gem::Version.new(version))
        end
      end
    end
  end
end
