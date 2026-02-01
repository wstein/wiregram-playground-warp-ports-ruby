# frozen_string_literal: true

require_relative 'token'
require_relative 'token_stream'

module WireGram
  module Core
    # Base Parser - Foundation for parsing
    class BaseParser
      attr_reader :tokens, :position, :errors

      def initialize(tokens)
        @tokens = tokens
        @position = 0
        @errors = []
      end

      def parse
        raise NotImplementedError, 'Subclasses must implement parse'
      end

      def current_token
        token_at(@position)
      end

      def peek_token(offset = 1)
        token_at(@position + offset)
      end

      def advance
        @position += 1
        # Notify streaming sources to drop consumed tokens
        if @tokens.is_a?(StreamingTokenStream)
          @tokens.consume_to(@position)
        end
      end

      def expect(type)
        token = current_token
        if token && token.type == type
          advance
          token
        else
          # Error recovery
          @errors << {
            type: 'unexpected_token',
            expected: type,
            got: token ? token.type : :eof,
            position: token ? token.position : @position
          }
          nil
        end
      end

      def at_end?
        token = current_token
        token.nil? || token.type == :eof
      end

      def synchronize
        token = current_token
        until at_end? || (token && token.type == :semicolon)
          advance
          token = current_token
        end
        advance unless at_end?
      end

      private

      def token_at(index)
        case @tokens
        when Array
          @tokens[index]
        else
          @tokens[index]
        end
      end
    end
  end
end
