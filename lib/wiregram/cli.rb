# frozen_string_literal: true

require 'json'
require 'optparse'
require_relative 'languages/expression'
require_relative 'languages/json'
require_relative 'languages/ucl'

module WireGram
  module CLI
    # Language discovery helper
    class Languages
      LANG_MAP = {
        'expression' => WireGram::Languages::Expression,
        'json' => WireGram::Languages::Json,
        'ucl' => WireGram::Languages::Ucl
      }.freeze

      def self.available
        LANG_MAP.keys
      end

      def self.module_for(name)
        LANG_MAP[name]
      end

      def self.supports?(name, method)
        case name
        when 'expression', 'json', 'ucl'
          [:process, :process_pretty, :tokenize, :tokenize_stream, :parse, :parse_stream].include?(method)
        else
          false
        end
      end
    end

    # CLI Runner
    class Runner
      def self.start(argv)
        new(argv).run
      end

      def initialize(argv)
        @argv = argv.dup
        @global = { 'format' => 'text' }
        @simd = false
        @symbolic_utf8 = false
        @upfront_rules = false
        @branchless = false
        @brzozowski = false
        @gpu = false
        @verbose = false
      end

      def run
        consume_global_options
        command = @argv.shift

        case command
        when nil, 'help', '--help', '-h'
          print_help
        when 'list'
          list_languages
        when 'server'
          start_server
        when 'snapshot'
          handle_snapshot(@argv)
        else
          if command && Languages.available.include?(command)
            language = command
            action = @argv.shift || 'help'
            @argv = parse_common_flags(@argv)

            if action == 'benchmark'
              handle_benchmark(language, @argv)
            else
              handle_language(language, action, @argv)
            end
          else
            warn "Unknown command: #{command}"
            print_help
            exit 1
          end
        end
      end

      private

      def parse_common_flags(argv)
        remaining = []
        OptionParser.new do |opts|
          opts.on('--simd', 'Enable SIMD acceleration') { @simd = true }
          opts.on('--symbolic-utf8', 'Enable symbolic UTF-8 processing') { @symbolic_utf8 = true }
          opts.on('--upfront-rules', 'Enable upfront lexing rules') { @upfront_rules = true }
          opts.on('--branchless', 'Enable branchless Stage 2 dispatch') { @branchless = true }
          opts.on('--brzozowski', 'Enable Brzozowski Derivatives engine') { @brzozowski = true }
          opts.on('--gpu', 'Enable M4 GPU acceleration') { @gpu = true }
          opts.on('--unquoted-simd', 'Enable SIMD for unquoted strings') { @simd = true }
          opts.on('--full-opt', 'Enable all optimizations') do
            @simd = true
            @symbolic_utf8 = true
            @upfront_rules = true
            @branchless = true
          end
          opts.on('--verbose', 'Show internal logs') { @verbose = true }
        end.parse!(argv)
        argv
      rescue OptionParser::InvalidOption
        argv
      end

      def print_help
        puts <<~HELP
          WireGram umbrella CLI

          Usage:
            wiregram list                            # list available languages
            wiregram <language> help                 # show help for language
            wiregram <language> inspect [opts]       # run full pipeline
            wiregram <language> parse [opts]         # parse input
            wiregram <language> tokenize [opts]      # show tokens
            wiregram <language> benchmark <type> <file>
            wiregram server [--port 4567]            # start HTTP server
            wiregram snapshot --generate --language json

          Global options:
            --format json|text    Output format (default: text)

          Optimization flags:
            --simd, --symbolic-utf8, --upfront-rules, --branchless
            --brzozowski, --gpu, --unquoted-simd, --full-opt

          Examples:
            echo '{ "a":1 }' | wiregram json inspect --pretty --simd
            wiregram list
        HELP
      end

      def list_languages
        puts 'Available languages:'
        Languages.available.each { |lang| puts "  - #{lang}" }
      end

      def start_server
        require 'webrick'
        
        options = { port: 4567 }
        OptionParser.new do |opts|
          opts.on('--port PORT', Integer, 'HTTP port') { |p| options[:port] = p }
        end.parse!(@argv)

        server = WEBrick::HTTPServer.new(Port: options[:port], Logger: WEBrick::Log.new('/dev/null'))
        
        server.mount_proc '/v1/process' do |req, res|
          if req.request_method != 'POST'
            res.status = 405
            next
          end

          begin
            payload = JSON.parse(req.body)
            language = payload['language']
            input = payload['input'] || ''
            pretty = payload['pretty'] || false

            unless language && Languages.available.include?(language)
              res.status = 400
              res['Content-Type'] = 'application/json'
              res.body = { error: 'unsupported language' }.to_json
              next
            end

            result = process_language(language, input, pretty)
            res['Content-Type'] = 'application/json'
            res.body = result.to_json
          rescue JSON::ParserError
            res.status = 400
            res['Content-Type'] = 'application/json'
            res.body = { error: 'invalid json body' }.to_json
          rescue => e
            res.status = 500
            res['Content-Type'] = 'application/json'
            res.body = { error: e.message }.to_json
          end
        end

        trap('INT') { server.shutdown }

        puts "WireGram server running on http://localhost:#{options[:port]} (Ctrl-C to stop)"
        server.start
      end

      def handle_snapshot(argv)
        generate = false
        lang = nil

        OptionParser.new do |opts|
          opts.on('--generate', 'Generate snapshots') { generate = true }
          opts.on('--language LANG', 'Limit to language') { |v| lang = v }
        end.parse!(argv)

        if generate
          if lang
            system('rake', "snapshots:generate_for[#{lang}]")
          else
            system('rake', 'snapshots:generate')
          end
        else
          warn 'Specify --generate and optionally --language <name>'
        end
      end

      def handle_benchmark(language, argv)
        bench_type = argv.shift
        file_path = argv.shift

        unless bench_type && file_path && File.file?(file_path)
          warn 'Usage: wiregram <language> benchmark <tokenize|parse|process> <file>'
          exit 1
        end

        input = File.read(file_path)
        size_mb = input.bytesize.to_f / (1024 * 1024)

        warn "Benchmarking #{language} #{bench_type} on #{file_path} (#{size_mb.round(2)} MB)..."

        start_time = Time.now

        case bench_type
        when 'tokenize'
          tokenize_stream(language, input) { |_token| }
        when 'parse'
          parse_stream(language, input) { |_node| }
        when 'process'
          process_language(language, input, false)
        else
          warn "Unknown benchmark type: #{bench_type}"
          exit 1
        end

        duration = Time.now - start_time
        throughput = size_mb / duration

        puts '--- Benchmark Results ---'
        puts "File: #{file_path} (#{size_mb.round(2)} MB)"
        puts "Type: #{bench_type}"
        puts "Duration: #{(duration * 1000).round(2)} ms"
        puts "Throughput: #{throughput.round(2)} MB/s"
      end

      def handle_language(language, action, argv)
        unless Languages.available.include?(language)
          warn "Unknown language: #{language}"
          exit 1
        end

        case action
        when 'help', '--help', '-h'
          print_language_help(language)
        when 'inspect'
          input = read_input(argv)
          pretty = argv.include?('--pretty')
          result = process_language(language, input, pretty)
          output_result(result)
        when 'tokenize'
          input = read_input(argv)
          tokenize_stream(language, input) do |token|
            puts token.to_json
          end
        when 'parse'
          input = read_input(argv)
          parse_stream(language, input) do |node|
            puts node.to_json if node
          end
        else
          warn "Unknown action: #{action}"
          print_language_help(language)
          exit 1
        end
      end

      def print_language_help(language)
        puts "#{language} commands:"
        puts '  inspect [--pretty]              Run full pipeline'
        puts '  tokenize                        Show tokens'
        puts '  parse                           Show AST'
        puts '  benchmark <type> <file>         Benchmark performance'
      end

      def read_input(argv)
        if argv.first && !argv.first.start_with?('--') && File.file?(argv.first)
          File.read(argv.shift)
        elsif $stdin.tty?
          ''
        else
          $stdin.read
        end
      end

      def output_result(result)
        if @global['format'] == 'json' || ENV['WIREGRAM_FORMAT'] == 'json'
          puts JSON.pretty_generate(result)
        elsif result.is_a?(Hash)
          result.each do |k, v|
            puts "== #{k} =="
            puts JSON.pretty_generate(v) if v
            puts
          end
        else
          puts result
        end
      end

      def consume_global_options
        index = @argv.index('--format')
        if index && (value = @argv[index + 1])
          @global['format'] = value
          @argv.delete_at(index + 1)
          @argv.delete_at(index)
        end
      end

      def process_language(language, input, pretty)
        case language
        when 'expression'
          WireGram::Languages::Expression.process(input, verbose: @verbose)
        when 'json'
          if pretty
            WireGram::Languages::Json.process_pretty(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8,
                                                      use_upfront_rules: @upfront_rules, use_branchless: @branchless,
                                                      use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose)
          else
            WireGram::Languages::Json.process(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8,
                                              use_upfront_rules: @upfront_rules, use_branchless: @branchless,
                                              use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose)
          end
        when 'ucl'
          WireGram::Languages::Ucl.process(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8,
                                           use_upfront_rules: @upfront_rules, use_branchless: @branchless,
                                           use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose)
        else
          raise "Unknown language: #{language}"
        end
      end

      def tokenize_stream(language, input, &block)
        case language
        when 'expression'
          WireGram::Languages::Expression.tokenize_stream(input, verbose: @verbose, &block)
        when 'json'
          WireGram::Languages::Json.tokenize_stream(input, use_simd: @simd, verbose: @verbose, &block)
        when 'ucl'
          WireGram::Languages::Ucl.tokenize_stream(input, use_simd: @simd, verbose: @verbose, &block)
        else
          raise "Unknown language: #{language}"
        end
      end

      def parse_stream(language, input, &block)
        case language
        when 'expression'
          WireGram::Languages::Expression.parse_stream(input, verbose: @verbose, &block)
        when 'json'
          WireGram::Languages::Json.parse_stream(input, use_simd: @simd, verbose: @verbose, &block)
        when 'ucl'
          WireGram::Languages::Ucl.parse_stream(input, use_simd: @simd, verbose: @verbose, &block)
        else
          raise "Unknown language: #{language}"
        end
      end
    end
  end
end
