#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/wiregram'

# Simple test suite without RSpec
def test(description)
  print "Testing #{description}... "
  yield
  puts '✓'
rescue => e
  puts "✗ (#{e.message})"
  puts e.backtrace.first(5)
  exit 1
end

puts 'Running WireGram basic tests...'
puts

# Test version
test('version exists') do
  raise 'No version' unless WireGram::VERSION
end

# Test Token
test('Token creation') do
  token = WireGram::Core::Token.new(:string, 'hello', 0)
  raise 'Wrong type' unless token.type == :string
  raise 'Wrong value' unless token.value == 'hello'
  raise 'Wrong position' unless token.position == 0
end

test('Token to_h') do
  token = WireGram::Core::Token.new(:number, 42, 10)
  hash = token.to_h
  raise 'Wrong type in hash' unless hash['type'] == 'number'
  raise 'Wrong value in hash' unless hash['value'] == 42
  raise 'Wrong position in hash' unless hash['position'] == 10
end

# Test Node
test('NumberNode creation') do
  node = WireGram::Core::NumberNode.new(42)
  raise 'Wrong type' unless node.type == :number
  raise 'Wrong value' unless node.value == 42
end

test('BinaryNode with children') do
  left = WireGram::Core::NumberNode.new(1)
  right = WireGram::Core::NumberNode.new(2)
  add = WireGram::Core::BinaryNode.new(:add, [left, right])
  raise 'Wrong type' unless add.type == :add
  raise 'Wrong children count' unless add.children.size == 2
end

test('Node to_h') do
  node = WireGram::Core::NumberNode.new(42)
  hash = node.to_h
  raise 'Wrong type' unless hash['type'] == 'number'
  raise 'Wrong value' unless hash['value'] == 42
end

# Test CLI Languages
test('Languages.available') do
  langs = WireGram::CLI::Languages.available
  raise 'Missing expression' unless langs.include?('expression')
  raise 'Missing json' unless langs.include?('json')
  raise 'Missing ucl' unless langs.include?('ucl')
end

test('Languages.module_for') do
  mod = WireGram::CLI::Languages.module_for('json')
  raise 'Wrong module' unless mod == WireGram::Languages::Json
end

# Test Scanner
test('Scanner creation') do
  scanner = WireGram::Core::Scanner.new('hello world')
  raise 'Scanner failed' unless scanner.pos == 0
end

# Test token types
test('TokenType constants') do
  raise 'Missing EOF' unless WireGram::Core::TokenType::EOF == :eof
  raise 'Missing STRING' unless WireGram::Core::TokenType::STRING == :string
  raise 'Missing NUMBER' unless WireGram::Core::TokenType::NUMBER == :number
end

# Test node types
test('NodeType constants') do
  raise 'Missing PROGRAM' unless WireGram::Core::NodeType::PROGRAM == :program
  raise 'Missing ADD' unless WireGram::Core::NodeType::ADD == :add
  raise 'Missing NUMBER' unless WireGram::Core::NodeType::NUMBER == :number
end

puts
puts 'All tests passed! ✓'
