sass-spec
=========

A test suite for Sass. The test cases are all in the `/spec` folder.

Run tests against Ruby Sass with the `sass-spec.rb` file in the root directory.

    ./sass-spec.rb 

Full text help is available if you run that w/ the help options.

## Organization

The tests are organized this way:

	* basic - The core tests taken from Sass' early development
	* scss - The tests suite written for the introduction of scss
	* libsass-open-issues - Tests for known libsass breakages. These are not run automatically.
	* libsass-closed-issues - Tests for closed issues in the libsass directory.
 	* maps - Testing maps
	* extends - Testing extends
	* libsass-todo - Tests taken from Ruby Sass and moved over here, that do not pass in libsass yet.

## Ruby Sass

All tests with scss files named `input.disabled.scss` should be for non-supported tests.

Ruby 2.1.0 contained a regression that changed the order of some selectors, causing test failures in sass-spec. That was fixed in Ruby 2.1.1. If you're running sass-spec against a Ruby Sass, please be sure not to use Ruby 2.1.0.

## LibSass

After installing a libsass dev enviroment (see libsass readme... sassc, this spec, and libsass), the tests are run by going
to the libsass folder and running ./script/spec.

## Contribution

This project needs maintainers! There will be an ongoing process of simplifying test cases, reporting new issues and testing them here, and managing mergers of official test cases.

This project requires help with the Ruby test drivers (better output, detection modes, etc) AND just with managing the issues and writing test cases.
