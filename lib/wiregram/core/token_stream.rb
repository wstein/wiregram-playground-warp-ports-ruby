# frozen_string_literal: true

require_relative 'token'

module WireGram
  module Core
    # TokenStream provides lazy access to tokens produced by a lexer
    class TokenStream
      def initialize(lexer)
        @lexer = lexer
        @cache = []
        @eof_produced = false
      end

      def [](index)
        ensure_filled(index)
        @cache[index]
      end

      def length
        ensure_all
        @cache.size
      end

      def tokens
        ensure_all
        @cache
      end

      private

      def ensure_filled(index)
        while @cache.size <= index && !@eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token.type == :eof
        end
      end

      def ensure_all
        ensure_filled(0) unless @cache.any?
        until @eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token.type == :eof
        end
      end
    end

    # StreamingTokenStream for memory-efficient parsing
    class StreamingTokenStream
      def initialize(lexer, buffer_size = 8)
        @lexer = lexer
        @buffer_size = buffer_size
        @base = 0
        @buffer = []
        @eof = false
      end

      def [](index)
        return nil if index < @base

        rel = index - @base
        while !@eof && @buffer.size <= rel
          token = @lexer.next_token
          token = Token.new(:eof, nil, @base + @buffer.size) if token.nil?
          @buffer << token
          @eof = true if token.type == :eof
        end
        @buffer[rel]
      end

      # Ruby doesn't support ? in method names like this
      # Use regular [] which already returns nil if out of bounds

      def consume_to(position)
        return if position <= @base

        drop = position - @base
        return unless drop.positive?

        @buffer.shift(drop)
        @base += drop
      end

      def next
        token = self[@base]
        consume_to(@base + 1)
        token
      end
    end
  end
end
