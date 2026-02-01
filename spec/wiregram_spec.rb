# frozen_string_literal: true

require 'rspec'
require_relative '../lib/wiregram'

RSpec.describe WireGram do
  it 'has a version number' do
    expect(WireGram::VERSION).not_to be nil
  end
end

RSpec.describe WireGram::Core::Token do
  it 'creates a token with type and value' do
    token = WireGram::Core::Token.new(:string, 'hello', 0)
    expect(token.type).to eq(:string)
    expect(token.value).to eq('hello')
    expect(token.position).to eq(0)
  end

  it 'converts to hash' do
    token = WireGram::Core::Token.new(:number, 42, 10)
    hash = token.to_h
    expect(hash['type']).to eq('number')
    expect(hash['value']).to eq(42)
    expect(hash['position']).to eq(10)
  end
end

RSpec.describe WireGram::Core::Node do
  it 'creates a simple node' do
    node = WireGram::Core::NumberNode.new(42)
    expect(node.type).to eq(:number)
    expect(node.value).to eq(42)
  end

  it 'creates nodes with children' do
    left = WireGram::Core::NumberNode.new(1)
    right = WireGram::Core::NumberNode.new(2)
    add = WireGram::Core::BinaryNode.new(:add, [left, right])
    
    expect(add.type).to eq(:add)
    expect(add.children.size).to eq(2)
  end
end

RSpec.describe WireGram::CLI::Languages do
  it 'lists available languages' do
    langs = WireGram::CLI::Languages.available
    expect(langs).to include('expression', 'json', 'ucl')
  end

  it 'gets module for language' do
    mod = WireGram::CLI::Languages.module_for('json')
    expect(mod).to eq(WireGram::Languages::Json)
  end
end
