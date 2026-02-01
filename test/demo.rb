#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/wiregram'

puts "=== WireGram Ruby Port Demo ==="
puts

# Demo 1: Token creation
puts "1. Token Creation:"
token = WireGram::Core::Token.new(:string, "hello", 0)
puts "   Created token: #{token.inspect}"
puts "   Token hash: #{token.to_h}"
puts

# Demo 2: AST Node creation
puts "2. AST Node Creation:"
num1 = WireGram::Core::NumberNode.new(10)
num2 = WireGram::Core::NumberNode.new(20)
add_node = WireGram::Core::BinaryNode.new(:add, [num1, num2])
puts "   Created node: #{add_node.inspect}"
puts "   Node type: #{add_node.type}"
puts "   Children: #{add_node.children.size}"
puts

# Demo 3: Node tree traversal
puts "3. AST Traversal:"
count = 0
add_node.traverse { |n| count += 1 }
puts "   Total nodes in tree: #{count}"
puts

# Demo 4: Node serialization
puts "4. Node Serialization:"
hash = add_node.to_h
puts "   Node as hash: #{JSON.pretty_generate(hash)}"
puts

# Demo 5: Scanner usage
puts "5. Scanner Demo:"
scanner = WireGram::Core::Scanner.new("hello world 123")
word = scanner.scan(/\w+/)
puts "   Scanned: '#{word}'"
scanner.scan(/\s+/)
word2 = scanner.scan(/\w+/)
puts "   Scanned: '#{word2}'"
scanner.scan(/\s+/)
num = scanner.scan(/\d+/)
puts "   Scanned number: '#{num}'"
puts

# Demo 6: Language availability
puts "6. Available Languages:"
WireGram::CLI::Languages.available.each do |lang|
  mod = WireGram::CLI::Languages.module_for(lang)
  puts "   - #{lang} (#{mod})"
end
puts

# Demo 7: Brzozowski engine
puts "7. Brzozowski Derivatives Engine:"
char_expr = WireGram::Core::Brzozowski::BChar.new('a'.ord)
engine = WireGram::Core::Brzozowski::Engine.new(char_expr)
puts "   Pattern matches 'a': #{engine.match?('a')}"
puts "   Pattern matches 'b': #{engine.match?('b')}"
puts

puts "=== Demo Complete ==="
