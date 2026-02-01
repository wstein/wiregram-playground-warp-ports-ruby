# frozen_string_literal: true

module WireGram
  module Core
    # SIMD Accelerator stub for Ruby
    # In the Crystal version, this uses ARM NEON instructions
    # For Ruby, we provide a pure Ruby fallback
    module SimdAccelerator
      # Scans a 16-byte block for structural characters
      # Returns [mask, is_ascii]
      def self.find_structural_bits(bytes, offset = 0)
        mask = 0
        is_ascii = true
        
        16.times do |i|
          return [mask, is_ascii] if offset + i >= bytes.size
          
          b = bytes[offset + i].ord
          is_ascii = false if b >= 0x80
          
          # Structural chars: { } [ ] : , " \ = ; # / and whitespace
          if b <= 0x20 || [0x7b, 0x7d, 0x5b, 0x5d, 0x3a, 0x2c, 0x22, 0x5c, 0x3d, 0x3b, 0x23, 0x2f].include?(b)
            mask |= (1 << i)
          end
        end
        
        [mask, is_ascii]
      end

      # Check if 16-byte block is ASCII
      def self.is_ascii_16?(bytes, offset = 0)
        16.times do |i|
          return true if offset + i >= bytes.size
          return false if bytes[offset + i].ord >= 0x80
        end
        true
      end
    end
  end
end
