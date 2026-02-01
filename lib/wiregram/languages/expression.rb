# frozen_string_literal: true

require_relative '../core/lexer'
require_relative '../core/parser'
require_relative '../core/node'

module WireGram
  module Languages
    module Expression
      # UOM (Unit of Meaning) for Expression language
      class UOM
        attr_reader :root

        def initialize(root)
          @root = root
        end
      end

      # Stub implementation for Expression language
      def self.process(input, verbose: false)
        { 
          uom: UOM.new(nil),
          ast: nil,
          tokens: []
        }
      end

      def self.tokenize_stream(input, verbose: false, &block)
        # Stub
      end

      def self.parse_stream(input, verbose: false, &block)
        # Stub
      end
    end
  end
end
