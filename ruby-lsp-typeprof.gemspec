# frozen_string_literal: true

require_relative "lib/ruby/lsp/typeprof/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-typeprof"
  spec.version = Ruby::Lsp::Typeprof::VERSION
  spec.authors = ["Takumi Shotoku"]
  spec.email = ["sinsoku.listy@gmail.com"]

  spec.summary = "Ruby LSP addon for TypeProf v2 type inference"
  spec.description = "A Ruby LSP addon that integrates TypeProf v2 to provide type information on hover."
  spec.homepage = "https://github.com/sinsoku/ruby-lsp-typeprof"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sinsoku/ruby-lsp-typeprof"
  spec.metadata["changelog_uri"] = "https://github.com/sinsoku/ruby-lsp-typeprof/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-lsp", ">= 0.12.0"
  spec.add_dependency "typeprof", ">= 0.30.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
