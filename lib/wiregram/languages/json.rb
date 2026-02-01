# frozen_string_literal: true

require 'json'
require_relative '../core/lexer'
require_relative '../core/parser'
require_relative '../core/node'

module WireGram
  module Languages
    module Json
      # UOM for JSON language
      class UOM
        attr_reader :root

        def initialize(root)
          @root = root
        end
      end

      # Stub implementations
      def self.process(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false, 
                       use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false)
        {
          uom: UOM.new(nil),
          ast: nil,
          tokens: []
        }
      end

      def self.process_pretty(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false,
                              use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false)
        process(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, 
                use_upfront_rules: use_upfront_rules, use_branchless: use_branchless,
                use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
      end

      def self.tokenize(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false,
                        use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false)
        []
      end

      def self.tokenize_stream(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false,
                               use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false, &block)
        # Stub
      end

      def self.parse(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false,
                     use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false)
        nil
      end

      def self.parse_stream(input, use_simd: false, use_symbolic_utf8: false, use_upfront_rules: false,
                            use_branchless: false, use_brzozowski: false, use_gpu: false, verbose: false, &block)
        # Stub
      end
    end
  end
end
