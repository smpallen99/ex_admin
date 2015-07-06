# fs-mode

A drop-in replacement for Node's native `fs` module which adds `fs.Async` and
`fs.Sync` namespaces with identical method names and APIs. So
`fs.Async.readFile` is the same as `fs.readFile`, and `fs.Sync.readFile` is a
wrapped version of `fs.readFileSync` which passes the result to a callback
instead of just returning it.

## Installation

`npm install --save fs-mode`

## Usage

```js
var fs = require('fs-mode');

function myModule (fs, otherArg, callback) {
	// normal fs stuff using async methods
	fs.readFile('myFile', function (err, data) {
		if (err) return callback(err);
		var result = doSomethingTo(data);
		callback(null, result);
	});
}

module.exports = {
	myModule: myModule.bind(null, fs.Async),
	myModuleSync: function (otherArg) {
		var result;
		myModule(fs.Sync, otherArg, function (err, data) {
			if (err) throw err;
			result = data;
		});
		return result;
	}
}
```

As you can see, this makes it pretty easy to adapt an existing async module
using fs methods to also provide a sync option. For a real-world example of
this type of conversion, see https://github.com/es128/progeny/commit/6685987033036f9c6c1dc5afcc69268221681538

#### Use with other fs replacements

Such as graceful-fs or fs-extra

```js
var fs = require('fs-mode')('graceful-fs');
```

## License

[ISC](https://raw.github.com/es128/fs-mode/master/LICENSE)
