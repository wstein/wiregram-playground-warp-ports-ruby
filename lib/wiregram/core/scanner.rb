# frozen_string_literal: true

require 'strscan'

module WireGram
  module Core
    # Lightweight scanner backed by Ruby's StringScanner
    class Scanner
      attr_accessor :pos
      attr_reader :matched

      def initialize(source)
        @source = source
        @scanner = StringScanner.new(source)
        @pos = 0
        @matched = nil
      end

      def scan(regex)
        @scanner.pos = @pos
        result = @scanner.scan(regex)
        if result
          @matched = result
          @pos = @scanner.pos
        end
        result
      end

      def check(regex)
        @scanner.pos = @pos
        result = @scanner.check(regex)
        @matched = result if result
        result
      end

      def skip(regex)
        @scanner.pos = @pos
        result = @scanner.skip(regex)
        @pos = @scanner.pos if result
        result
      end

      def scan_until(regex)
        @scanner.pos = @pos
        result = @scanner.scan_until(regex)
        if result
          @matched = @scanner.matched
          @pos = @scanner.pos
        end
        result
      end
    end
  end
end
