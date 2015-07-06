require "open3"
# This represents a specific test case.
class SassSpec::TestCase
  def initialize(input_scss, expected_css, options = {})
    @input_path = input_scss
    @expected_path = expected_css
    @options = options
  end

  def name
    @input_path.dirname.to_s.sub(Dir.pwd + "/", "")
  end

  def input_path
    @input_path
  end

  def expected_path
    @expected_path
  end

  def todo?
    @input_path.to_s.include? "todo"
  end

  def output
    if @output
      return @output
    end
    stdout, stderr, status = Open3.capture3("#{@options[:sass_executable]} #{@input_path}")
    cleaned = _clean_output(stdout)
    @output ||= [stdout, cleaned, stderr, status]
  end

  def expected
    @expected ||= _clean_output File.read(@expected_path)
  end

  def _clean_output(css)
    css.gsub(/\s+/, " ")
       .gsub(/ *\{/, " {\n")
       .gsub(/([;,]) */, "\\1\n")
       .gsub(/ *\} */, " }\n")
       .strip
  end
end
