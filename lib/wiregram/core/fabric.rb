# frozen_string_literal: true

require_relative 'node'
require_relative 'token'

module WireGram
  module Core
    # Digital Fabric - A reversible representation of source code
    class Fabric
      attr_reader :source, :ast, :tokens

      def initialize(source, ast, tokens = [])
        @source = source
        @ast = ast
        @tokens = tokens
      end

      def to_source
        unweave(@ast)
      end

      def find_patterns(pattern_type)
        case pattern_type
        when :arithmetic_operations
          @ast.find_all { |node| [:add, :subtract, :multiply, :divide].include?(node.type) }
        when :literals
          @ast.find_all { |node| [:number, :string].include?(node.type) }
        when :identifiers
          @ast.find_all { |node| node.type == :identifier }
        else
          []
        end
      end

      def analyze
        # Stub for analyzer
        require_relative '../engines/analyzer'
        WireGram::Engines::Analyzer.new(self)
      end

      def transform(transformation = nil, &block)
        # Stub for transformer
        require_relative '../engines/transformer'
        transformer = WireGram::Engines::Transformer.new(self)
        transformer.apply(transformation, &block)
      end

      private

      def unweave(node)
        case node.type
        when :program
          node.children.map { |child| unweave(child) }.join(' ')
        when :ucl_program
          # Placeholder for UCL serializer
          node.children.map { |c| unweave(c) }.join("\n")
        when :pair
          key = node.children[0]
          value = node.children[1]
          "#{key.value} = #{unweave(value)};"
        when :object
          inner = node.children.map { |c| "  #{unweave(c)}" }.join("\n")
          "{\n#{inner}\n}"
        when :array
          "[#{node.children.map { |c| unweave(c) }.join(', ')}]"
        when :number
          node.value.to_s
        when :string
          "\"#{node.value}\""
        when :identifier
          node.value.to_s
        when :boolean
          node.value ? 'true' : 'false'
        when :null
          'null'
        when :add
          "#{unweave(node.children[0])} + #{unweave(node.children[1])}"
        when :subtract
          "#{unweave(node.children[0])} - #{unweave(node.children[1])}"
        when :multiply
          "#{unweave(node.children[0])} * #{unweave(node.children[1])}"
        when :divide
          "#{unweave(node.children[0])} / #{unweave(node.children[1])}"
        when :assign
          "let #{node.children[0].value} = #{unweave(node.children[1])}"
        else
          node.value.to_s
        end
      end
    end
  end
end
