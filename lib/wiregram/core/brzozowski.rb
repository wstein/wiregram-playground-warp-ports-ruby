# frozen_string_literal: true

module WireGram
  module Core
    # Brzozowski Derivatives Engine for regex matching
    module Brzozowski
      # Base expression class
      class Expression
        def nullable?
          raise NotImplementedError
        end

        def derive(char)
          raise NotImplementedError
        end
      end

      class BEmpty < Expression
        def nullable?
          false
        end

        def derive(char)
          self
        end
      end

      class BEpsilon < Expression
        def nullable?
          true
        end

        def derive(char)
          EMPTY
        end
      end

      class BChar < Expression
        attr_reader :byte

        def initialize(byte)
          @byte = byte
        end

        def nullable?
          false
        end

        def derive(char)
          char == @byte ? EPSILON : EMPTY
        end
      end

      class BCharRange < Expression
        attr_reader :start_byte, :end_byte

        def initialize(start_byte, end_byte)
          @start_byte = start_byte
          @end_byte = end_byte
        end

        def nullable?
          false
        end

        def derive(char)
          (char >= @start_byte && char <= @end_byte) ? EPSILON : EMPTY
        end
      end

      class BAlternation < Expression
        attr_reader :left, :right

        def initialize(left, right)
          @left = left
          @right = right
        end

        def nullable?
          @left.nullable? || @right.nullable?
        end

        def derive(char)
          BAlternation.new(@left.derive(char), @right.derive(char)).simplify
        end

        def simplify
          return @right if @left.is_a?(BEmpty)
          return @left if @right.is_a?(BEmpty)
          self
        end
      end

      class BConcatenation < Expression
        attr_reader :left, :right

        def initialize(left, right)
          @left = left
          @right = right
        end

        def nullable?
          @left.nullable? && @right.nullable?
        end

        def derive(char)
          d_left = BConcatenation.new(@left.derive(char), @right)
          if @left.nullable?
            BAlternation.new(d_left, @right.derive(char)).simplify
          else
            d_left
          end
        end
      end

      class BKleeneStar < Expression
        attr_reader :inner

        def initialize(inner)
          @inner = inner
        end

        def nullable?
          true
        end

        def derive(char)
          BConcatenation.new(@inner.derive(char), self)
        end
      end

      EMPTY = BEmpty.new
      EPSILON = BEpsilon.new

      # Engine for matching using derivatives
      class Engine
        attr_accessor :root

        def initialize(root)
          @root = root
        end

        def match?(bytes)
          current = @root
          bytes.each_byte do |b|
            current = current.derive(b)
            return false if current.is_a?(BEmpty)
          end
          current.nullable?
        end
      end
    end
  end
end
