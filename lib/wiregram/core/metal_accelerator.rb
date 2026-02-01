# frozen_string_literal: true

module WireGram
  module Core
    # Metal Accelerator stub for Ruby
    # In the Crystal version, this uses Apple M4 GPU
    # For Ruby, we provide a fallback
    module MetalAccelerator
      def self.available?
        false
      end

      def self.match_parallel_brzozowski(pattern, inputs)
        # Fallback: return all false
        Array.new(inputs.size, false)
      end
    end
  end
end
