# frozen_string_literal: true

module WireGram
  module Engines
    # Transformer engine for transforming AST
    class Transformer
      attr_reader :fabric

      def initialize(fabric)
        @fabric = fabric
      end

      def apply(transformation = nil, &block)
        if block_given?
          transform_node(@fabric.ast, &block)
        else
          @fabric.ast
        end
      end

      private

      def transform_node(node, &block)
        transformed = yield node
        return transformed if transformed

        # Transform children
        new_children = node.children.map { |child| transform_node(child, &block) }
        node.with(children: new_children)
      end
    end
  end
end
