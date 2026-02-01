# frozen_string_literal: true

# WireGram root module
module WireGram
  VERSION = '0.1.0'
end

# Load all core modules
require_relative 'wiregram/core/token'
require_relative 'wiregram/core/node'
require_relative 'wiregram/core/scanner'
require_relative 'wiregram/core/token_stream'
require_relative 'wiregram/core/lexer'
require_relative 'wiregram/core/parser'
require_relative 'wiregram/core/brzozowski'
require_relative 'wiregram/core/fabric'
require_relative 'wiregram/core/simd_accelerator'
require_relative 'wiregram/core/metal_accelerator'

# Load engines
require_relative 'wiregram/engines/analyzer'
require_relative 'wiregram/engines/recovery'
require_relative 'wiregram/engines/transformer'

# Load languages
require_relative 'wiregram/languages/expression'
require_relative 'wiregram/languages/json'
require_relative 'wiregram/languages/ucl'

# Load CLI
require_relative 'wiregram/cli'
