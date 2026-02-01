# frozen_string_literal: true

module WireGram
  module Engines
    # Analyzer engine for analyzing fabric
    class Analyzer
      attr_reader :fabric

      def initialize(fabric)
        @fabric = fabric
      end

      def complexity
        count_nodes(@fabric.ast)
      end

      def depth
        calculate_depth(@fabric.ast)
      end

      private

      def count_nodes(node)
        1 + node.children.sum { |child| count_nodes(child) }
      end

      def calculate_depth(node, current_depth = 0)
        return current_depth if node.children.empty?
        node.children.map { |child| calculate_depth(child, current_depth + 1) }.max
      end
    end
  end
end
