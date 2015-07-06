
test: node_modules
	@./node_modules/.bin/mocha \
		--timeout 300 \
		--require should \
		--bail \
		--reporter spec

node_modules: package.json
	@npm install

.PHONY: test