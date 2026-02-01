# frozen_string_literal: true

require 'json'

module WireGram
  module Core
    # NodeType symbols - in Ruby we use symbols
    module NodeType
      PROGRAM = :program
      ASSIGN = :assign
      ADD = :add
      SUBTRACT = :subtract
      MULTIPLY = :multiply
      DIVIDE = :divide
      GROUP = :group
      IDENTIFIER = :identifier
      NUMBER = :number
      STRING = :string
      BOOLEAN = :boolean
      NULL = :null
      OBJECT = :object
      PAIR = :pair
      ARRAY = :array
      DIRECTIVE = :directive
      UCL_PROGRAM = :ucl_program
      HEX_NUMBER = :hex_number

      ALL_TYPES = [
        PROGRAM, ASSIGN, ADD, SUBTRACT, MULTIPLY, DIVIDE, GROUP,
        IDENTIFIER, NUMBER, STRING, BOOLEAN, NULL, OBJECT, PAIR,
        ARRAY, DIRECTIVE, UCL_PROGRAM, HEX_NUMBER
      ].freeze
    end

    # DirectiveInfo structure
    class DirectiveInfo
      attr_reader :name, :args, :path

      def initialize(name, args = nil, path = nil)
        @name = name
        @args = args
        @path = path
      end
    end

    # Base AST Node class
    class Node
      def type
        raise NotImplementedError, 'Subclass must implement type'
      end

      def value
        nil
      end

      def children
        []
      end

      def metadata
        nil
      end

      def with(type: self.type, value: self.value, children: self.children, metadata: self.metadata)
        Node.create(type, value: value, children: children, metadata: metadata)
      end

      def traverse(&block)
        yield self
        children.each { |child| child.traverse(&block) }
      end

      def find_all(&block)
        results = []
        traverse do |node|
          results << node if yield node
        end
        results
      end

      def to_h
        hash = {}
        hash['type'] = type_name
        hash['value'] = serialize_value(value)
        hash['children'] = children.map(&:to_h)
        
        md_hash = {}
        (metadata || {}).each do |key, val|
          next if key == :raw
          md_hash[key.to_s] = val
        end
        hash['metadata'] = md_hash
        hash
      end

      def inspect
        "#<Node type=#{type_name} value=#{value.inspect} children=#{children.size}>"
      end

      def to_detailed_string(depth = 0, max_depth = 3)
        return '...' if depth > max_depth

        indent = '  ' * depth
        result = "#{indent}#<Node type=#{type_name}"
        result += " value=#{value.inspect}" if value

        if children.any?
          result += " children=#{children.size}>"
          children.each do |child|
            result += "\n#{child.to_detailed_string(depth + 1, max_depth)}"
          end
        else
          result += '>'
        end

        result
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      def self.create(type, value: nil, children: nil, metadata: nil)
        type_sym = type.is_a?(Symbol) ? type : symbol_to_type(type)
        build(type_sym, value, children, metadata)
      end

      private

      def type_name
        type.to_s
      end

      def serialize_value(val)
        case val
        when nil
          nil
        when Float
          if val.infinite?
            val.positive? ? 'Infinity' : '-Infinity'
          else
            val
          end
        when DirectiveInfo
          {
            'name' => val.name,
            'args' => val.args || {},
            'path' => val.path
          }
        else
          val
        end
      end

      def self.build(type, value, children, metadata)
        case type
        when NodeType::PROGRAM
          ProgramNode.new(children || [])
        when NodeType::ASSIGN
          AssignNode.new(children || [])
        when NodeType::ADD, NodeType::SUBTRACT, NodeType::MULTIPLY, NodeType::DIVIDE
          BinaryNode.new(type, children || [])
        when NodeType::GROUP
          GroupNode.new(children || [])
        when NodeType::IDENTIFIER
          raise 'Identifier node requires a String value' unless value.is_a?(String)
          IdentifierNode.new(value)
        when NodeType::NUMBER
          NumberNode.new(value, metadata)
        when NodeType::STRING
          raise 'String node requires a String value' unless value.is_a?(String)
          StringNode.new(value, metadata)
        when NodeType::BOOLEAN
          raise 'Boolean node requires a Bool value' unless [true, false].include?(value)
          BooleanNode.new(value)
        when NodeType::NULL
          NullNode.new
        when NodeType::OBJECT
          ObjectNode.new(children || [])
        when NodeType::PAIR
          PairNode.new(children || [])
        when NodeType::ARRAY
          ArrayNode.new(children || [])
        when NodeType::DIRECTIVE
          raise 'Directive node requires DirectiveInfo' unless value.is_a?(DirectiveInfo)
          DirectiveNode.new(value)
        when NodeType::UCL_PROGRAM
          UclProgramNode.new(children || [])
        when NodeType::HEX_NUMBER
          raise 'HexNumber node requires a String value' unless value.is_a?(String)
          HexNumberNode.new(value)
        else
          raise "Unknown node type: #{type}"
        end
      end

      def self.symbol_to_type(sym)
        NodeType::ALL_TYPES.include?(sym) ? sym : raise("Unknown node symbol: #{sym}")
      end
    end

    # Concrete Node subclasses
    class ProgramNode < Node
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def type
        NodeType::PROGRAM
      end

      def children
        @statements
      end
    end

    class UclProgramNode < Node
      attr_reader :items

      def initialize(items)
        @items = items
      end

      def type
        NodeType::UCL_PROGRAM
      end

      def children
        @items
      end
    end

    class AssignNode < Node
      attr_reader :identifier, :expression

      def initialize(children)
        @identifier = children[0]
        @expression = children[1]
      end

      def type
        NodeType::ASSIGN
      end

      def children
        [@identifier, @expression]
      end
    end

    class BinaryNode < Node
      attr_reader :operator_type, :left, :right

      def initialize(operator_type, children)
        @operator_type = operator_type
        @left = children[0]
        @right = children[1]
      end

      def type
        @operator_type
      end

      def children
        [@left, @right]
      end
    end

    class GroupNode < Node
      attr_reader :inner

      def initialize(children)
        @inner = children[0]
      end

      def type
        NodeType::GROUP
      end

      def children
        [@inner]
      end
    end

    class IdentifierNode < Node
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def type
        NodeType::IDENTIFIER
      end

      def value
        @name
      end
    end

    class NumberNode < Node
      attr_reader :number, :meta

      def initialize(value, metadata = nil)
        raw = metadata && metadata[:raw] == true
        @number = case value
                  when Float
                    value
                  when Integer
                    value
                  when String
                    if raw
                      value
                    else
                      value.include?('.') || value.include?('e') || value.include?('E') ? value.to_f : value.to_i
                    end
                  else
                    value.to_s.to_i
                  end
        @meta = metadata
      end

      def type
        NodeType::NUMBER
      end

      def value
        @number
      end

      def metadata
        @meta
      end
    end

    class StringNode < Node
      attr_reader :text, :meta

      def initialize(value, metadata = nil)
        @text = value
        @meta = metadata
      end

      def type
        NodeType::STRING
      end

      def value
        @text
      end

      def metadata
        @meta
      end
    end

    class BooleanNode < Node
      attr_reader :flag

      def initialize(flag)
        @flag = flag
      end

      def type
        NodeType::BOOLEAN
      end

      def value
        @flag
      end
    end

    class NullNode < Node
      def type
        NodeType::NULL
      end
    end

    class HexNumberNode < Node
      attr_reader :literal

      def initialize(literal)
        @literal = literal
      end

      def type
        NodeType::HEX_NUMBER
      end

      def value
        @literal
      end
    end

    class ObjectNode < Node
      attr_reader :pairs

      def initialize(pairs)
        @pairs = pairs
      end

      def type
        NodeType::OBJECT
      end

      def children
        @pairs
      end
    end

    class PairNode < Node
      attr_reader :key, :value_node

      def initialize(children)
        @key = children[0]
        @value_node = children[1]
      end

      def type
        NodeType::PAIR
      end

      def children
        [@key, @value_node]
      end
    end

    class ArrayNode < Node
      attr_reader :items

      def initialize(items)
        @items = items
      end

      def type
        NodeType::ARRAY
      end

      def children
        @items
      end
    end

    class DirectiveNode < Node
      attr_reader :info

      def initialize(info)
        @info = info
      end

      def type
        NodeType::DIRECTIVE
      end

      def value
        @info
      end
    end
  end
end
