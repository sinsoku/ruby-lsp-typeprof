# ruby-lsp-typeprof

A [Ruby LSP](https://github.com/Shopify/ruby-lsp) addon that integrates [TypeProf v2](https://github.com/ruby/typeprof) type inference into your editor. Get type information on hover without explicit type annotations.

## Requirements

- Ruby >= 3.3.0
- [TypeProf](https://github.com/ruby/typeprof) v2
- [Ruby LSP](https://github.com/Shopify/ruby-lsp)

## Installation

Add the gem to your application's Gemfile:

```ruby
group :development do
  gem "ruby-lsp-typeprof"
end
```

Then run:

```bash
bundle install
```

## Usage

Once installed, the addon is automatically detected by Ruby LSP. No additional configuration is required.

Hover over variables and method calls in your Ruby files to see TypeProf's inferred type information alongside Ruby LSP's built-in hover results.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```bash
bin/setup       # Install dependencies
rake test       # Run tests
rake rubocop    # Run linter
rake            # Run tests + linter
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sinsoku/ruby-lsp-typeprof. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sinsoku/ruby-lsp-typeprof/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ruby-lsp-typeprof project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sinsoku/ruby-lsp-typeprof/blob/main/CODE_OF_CONDUCT.md).
