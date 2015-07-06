validate: lint test

lint:
	@./node_modules/.bin/jshint \
		--verbose \
		index.js \
		lib/*.js

test:
	@./node_modules/.bin/mocha \
		--require should \
		--reporter spec

test-cov: lib-cov
	@CP_COV=1 ./node_modules/.bin/mocha \
		--require should \
		--reporter html-cov > coverage.html

lib-cov:
	@jscoverage lib lib-cov

.PHONY: test lint test-cov validate
