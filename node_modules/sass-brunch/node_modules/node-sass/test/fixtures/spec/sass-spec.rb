#!/usr/bin/env ruby

#This script requires a standard directory hierarchy which might be a bit cumbersome to set up
#
#The hierarchy looks like this near the leaves:
#...
#|-test_subclass_1
#| |-test_1
#| | |-input.scss
#| | --expected_output.css
#| --test_2
#|   |-input.scss
#|   --expected_output.css
#|-test_subclass_2
#| |-test_1
#| | |-input.scss
#| | --expected_output.css
#...
#the point is to have all the tests in their own folder in a file named input* with
#the output of running a command on it in the file expected_output* in the same directory

require_relative 'lib/sass_spec'
SassSpec::Runner.new(SassSpec::CLI.parse()).run
