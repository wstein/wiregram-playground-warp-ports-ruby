# frozen_string_literal: true

require_relative 'token'
require_relative 'scanner'

module WireGram
  module Core
    # Base Lexer class
    class BaseLexer
      attr_reader :source, :position

      def initialize(source)
        @source = source
        @scanner = Scanner.new(source)
        @position = 0
      end

      def next_token
        raise NotImplementedError, 'Subclass must implement next_token'
      end

      def tokenize
        tokens = []
        loop do
          token = next_token
          tokens << token
          break if token.type == :eof
        end
        tokens
      end
    end
  end
end
