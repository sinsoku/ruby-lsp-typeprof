[![Gem Version](https://badge.fury.io/rb/ruby-lsp-typeprof.svg)](https://badge.fury.io/rb/ruby-lsp-typeprof)
[![Test](https://github.com/sinsoku/ruby-lsp-typeprof/actions/workflows/test.yml/badge.svg)](https://github.com/sinsoku/ruby-lsp-typeprof/actions/workflows/test.yml)

# TypeProf add-on

The TypeProf add-on is a [Ruby LSP](https://github.com/Shopify/ruby-lsp) [add-on](https://shopify.github.io/ruby-lsp/add-ons.html) to provide type inference features.

## Installation

Add `ruby-lsp-typeprof` to your Gemfile:

```ruby
group :development do
  gem "ruby-lsp-typeprof", require: false
end
```

After running `bundle install`, restart Ruby LSP.

## Configuration

The add-on reads its settings from Ruby LSP's `addonSettings` mechanism.
Configure them in VS Code's `settings.json`:

```jsonc
{
  "rubyLsp.addonSettings": {
    "TypeProf": {
      "enabled": false,
      "enableCodeLens": false
    }
  }
}
```

You can place this configuration in either:

- **Workspace settings** (`.vscode/settings.json` at the repository root) —
  applies only to this project.
- **User settings** — applies to every workspace. See
  [User and Workspace Settings](https://code.visualstudio.com/docs/configure/settings)
  for the file location on each OS.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `enabled` | boolean | `true` | Master switch. When `false`, the add-on skips loading TypeProf entirely and disables every feature. |
| `enableCodeLens` | boolean | `true` | Show inferred type signatures as code lens above method definitions. Has no effect when `enabled` is `false`. |

After changing the setting, restart Ruby LSP via the "Ruby LSP: Restart"
command for it to take effect.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, run `bin/bump.rb` (pass `--minor` or `--major` to bump those segments) and push the resulting commit to `main`. The release workflow then publishes the gem to [rubygems.org](https://rubygems.org) and creates a GitHub release.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sinsoku/ruby-lsp-typeprof. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sinsoku/ruby-lsp-typeprof/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Lsp::Typeprof project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sinsoku/ruby-lsp-typeprof/blob/main/CODE_OF_CONDUCT.md).
