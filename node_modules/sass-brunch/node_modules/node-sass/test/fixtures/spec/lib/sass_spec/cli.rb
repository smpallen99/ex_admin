
module SassSpec::CLI
  require 'optparse'

  def self.parse
    options = {
      sass_executable: "sass",
      spec_directory: "spec",
      tap: false,
      skip: false,
      verbose: false,
      filter: "",
      limit: -1,
      unexpected_pass: false,
      nuke: false,

      # Constants
      input_file: 'input.scss',
      expected_file: 'expected_output.css'
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: ./sass-spec.rb [options]

Examples:
  Run `sassc --style compressed input.scss`:
  ./sass-spec.rb -c 'sass --style compressed'

  Run tests only in the spec/basic folder:
  ./sass-spec.rb spec/basic

This script will search for all files under the spec (or specified) directory
that are named input.scss. It will then run a specified binary and check that
the output matches the expected output. If you want set up your own test suite,
follow a similar hierarchy as described in the initial comment of this script
for your test hierarchy.

Make sure the command you provide prints to stdout.

"

      opts.on("-v", "--verbose", "Run verbosely") do
        options[:verbose] = true
      end

      opts.on("-t", "--tap", "Output TAP compatible report") do
        options[:tap] = true
      end

      opts.on("-c", "--command COMMAND", "Sets a specific binary to run (defaults to '#{options[:sass_executable]}')") do |v|
        options[:sass_executable] = v
      end

      opts.on("--ignore-todo", "Skip any folder named 'todo'") do
        options[:skip_todo] = true
      end

      opts.on("--filter PATTERN", "Run tests that match the pattern you provide") do |pattern|
        options[:filter] = pattern
      end

      opts.on("--limit NUMBER", "Limit the number of tests run to this positive integer.") do |limit|
        options[:limit] = limit.to_i
      end

      opts.on("-s", "--skip", "Skip tests that fail to exit successfully") do
        options[:skip] = true
      end

      opts.on("--nuke", "Write a new expected_output for every test from whichever engine we are using") do
        options[:nuke] = true
      end

      opts.on("--unexpected-pass", "When running the todo tests, flag as an error when a test passes which is marked as todo.") do
        options[:unexpected_pass] = true
      end

      opts.on("--silent", "Don't show any logs") do
        options[:silent] = true
      end
    end.parse!

    options[:spec_directory] = ARGV[0] if !ARGV.empty?

    options
  end
end
