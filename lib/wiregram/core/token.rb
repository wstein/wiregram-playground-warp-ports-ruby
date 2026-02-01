# frozen_string_literal: true

module WireGram
  module Core
    # TokenType enum - in Ruby we use symbols
    module TokenType
      EOF = :eof
      UNKNOWN = :unknown
      PLUS = :plus
      MINUS = :minus
      STAR = :star
      SLASH = :slash
      EQUALS = :equals
      LPAREN = :lparen
      RPAREN = :rparen
      LBRACE = :lbrace
      RBRACE = :rbrace
      LBRACKET = :lbracket
      RBRACKET = :rbracket
      COLON = :colon
      COMMA = :comma
      SEMICOLON = :semicolon
      STRING = :string
      NUMBER = :number
      BOOLEAN = :boolean
      NULL = :null
      IDENTIFIER = :identifier
      KEYWORD = :keyword
      DIRECTIVE = :directive
      INVALID_HEX = :invalid_hex
      HEX_NUMBER = :hex_number

      ALL_TYPES = [
        EOF, UNKNOWN, PLUS, MINUS, STAR, SLASH, EQUALS,
        LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
        COLON, COMMA, SEMICOLON, STRING, NUMBER, BOOLEAN,
        NULL, IDENTIFIER, KEYWORD, DIRECTIVE, INVALID_HEX, HEX_NUMBER
      ].freeze

      def self.from_symbol(sym)
        ALL_TYPES.include?(sym) ? sym : UNKNOWN
      end
    end

    # Token class
    class Token
      attr_reader :type, :value, :position, :extras

      def initialize(type, value = nil, position = 0, extras = nil)
        @type = type
        @value = value
        @position = position
        @extras = extras
      end

      def extra(key)
        @extras&.dig(key)
      end

      def extra?(key)
        @extras&.key?(key) || false
      end

      def [](key)
        case key
        when :type
          @type
        when :value
          @value
        when :position
          @position
        else
          @extras&.dig(key)
        end
      end

      def key?(key)
        case key
        when :type, :value, :position
          true
        else
          @extras&.key?(key) || false
        end
      end

      def to_h
        result = {
          'type' => @type.to_s,
          'value' => @value,
          'position' => @position
        }
        if @extras
          @extras.each do |key, val|
            result[key.to_s] = val
          end
        end
        result
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end
  end
end
