# frozen_string_literal: true

module RubyLsp
  module Typeprof
    module Compat
      # TypeProf < 0.33.2 reads files with File.read, which follows Encoding.default_external.
      # Without LANG that is US-ASCII and non-ASCII .rbs files fail to parse.
      # Fixed in ruby/typeprof#479 (v0.33.2); remove this once typeprof >= 0.33.2 is required.
      module Utf8DefaultExternal
        private

        def build_service(...)
          with_utf8_default_external { super }
        end

        def update_changed_file(...)
          with_utf8_default_external { super }
        end

        def with_utf8_default_external
          orig = Encoding.default_external
          return yield if orig == Encoding::UTF_8

          Encoding.default_external = Encoding::UTF_8
          begin
            yield
          ensure
            Encoding.default_external = orig
          end
        end
      end
    end
  end
end
