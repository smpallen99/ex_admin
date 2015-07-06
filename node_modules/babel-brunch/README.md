babel-brunch
===========
Brunch plugin using [babel](https://github.com/babel/babel) to turn ES6 code
into vanilla ES5 with no runtime required.

All the `.js` files in your project will be run through the babel compiler,
except those it is configured to ignore, unless you use the `pattern` option.

Installation
------------
`npm install --save babel-brunch`

Configuration
-------------
Set [babel options](https://babeljs.io/docs/usage/options) in your brunch
config (such as `brunch-config.coffee`) except for `filename` and `sourceMap`
which are handled internally.

Additionally, you can set an `ignore` value to specify which `.js` files in
your project should not be compiled by babel. By default, `ignore` is set to
`/^(bower_components|vendor)/`.

You can also set `pattern` to a regular expression that will match the file
paths you want compiled by babel, which will override the standard behavior of
compiling every `.js` file.

```coffee
plugins:
	babel:
		whitelist: ['arrowFunctions']
		format:
			semicolons: false
		ignore: [
			/^(bower_components|vendor)/
			'app/legacyES5Code/**/*'
		]
		pattern: /\.(es6|jsx)$/
```

Change Log
----------
[See release notes page on GitHub](https://github.com/babel/babel-brunch/releases)

License
-------
[ISC](https://raw.github.com/babel/babel-brunch/master/LICENSE)
