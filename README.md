# wiregram-playground-warp-ports-ruby

Ruby port of the WireGram framework from the original Crystal sources.

## Overview

This is a Ruby port of the WireGram lexer/parser framework, originally implemented in Crystal. WireGram provides a flexible foundation for building language processors with support for:

- **Expression language** - Simple arithmetic expressions
- **JSON** - Full JSON parsing with optimization flags
- **UCL** - Universal Configuration Language

## Installation

```bash
gem install wiregram
```

Or add to your Gemfile:

```ruby
gem 'wiregram'
```

## Usage

### Command Line

```bash
# List available languages
wiregram list

# Parse JSON
echo '{"key": "value"}' | wiregram json parse

# Inspect JSON with pretty output
wiregram json inspect --pretty < input.json

# Run benchmarks
wiregram json benchmark parse large_file.json

# Start HTTP server
wiregram server --port 4567
```

### Ruby API

```ruby
require 'wiregram'

# Process JSON
result = WireGram::Languages::Json.process('{"key": "value"}')

# Use core classes
token = WireGram::Core::Token.new(:string, "hello", 0)
node = WireGram::Core::Node.create(:number, value: 42)
```

## Architecture

The Ruby port maintains the same architecture as the Crystal version:

- `lib/wiregram/core/` - Core lexer/parser infrastructure
- `lib/wiregram/engines/` - Analysis and transformation engines
- `lib/wiregram/languages/` - Language-specific implementations
- `lib/wiregram/cli.rb` - Command-line interface

## Optimization Flags

The port includes stubs for the Crystal version's optimization features:

- `--simd` - SIMD acceleration (stub in Ruby)
- `--symbolic-utf8` - Symbolic UTF-8 processing
- `--upfront-rules` - Upfront lexing rules
- `--branchless` - Branchless dispatch
- `--brzozowski` - Brzozowski derivatives engine
- `--gpu` - GPU acceleration (stub in Ruby)

## Development

```bash
# Run the CLI
ruby -Ilib bin/wiregram list

# Run tests
rspec spec/
```

## License

MIT License - see LICENSE file for details.

## Credits

Ported from the Crystal implementation in [wiregram-playground](https://github.com/wstein/wiregram-playground).