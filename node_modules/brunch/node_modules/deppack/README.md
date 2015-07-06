# Deppack

### Simple module to pack files with dependencies.

Example:

*awesomeModule/index.js*
```javascript
var lastOf = require('./lastOf')
var firstOf = require('./firstOf')

module.exports = {
  lastOf:  lastOf,
  firstOf: firstOf
}
```

*awesomeModule/lastOf.js*
```javascript
var _ = require('underscore')

module.exports = function (array) {
  return _.last(array)
}
```

*awesomeModule/firstOf.js*
```javascript
var _ = require('underscore')

module.exports = function (array) {
  return _.first(array)
}
```

*write.js*
```javascript
var fs = require('fs');
var deppack = require('deppack');

deppack('node_modules/awesomeModule/index.js', {basedir: '.', rollback: true}, function (err, data) {
  //data is index.js with loaded deps.
  fs.writeFileSync('bundle.js', data);
})

```

In bundle.js `require('moduleName')` is equal to use it with node.js:

*bundle.js*
```javascript
lastOf = require('awesomeModule').lastOf
console.log(lastOf([2,4,8,1,3]))
```

# API

`deppack(path, options, callback)` - takes module path, options and callback with `error` and `data` arguments.

## Options

* __basedir__: _Optional_. Module's root directory. Default: `process.cwd`
* __rollback__: _Optional_. If module(or one of dependencies) depends on node.js core module, whole module will be ignored. `data` argument in callback will return empty string.
* __ignoreRequireDefinition__: _Optional_. Will ignore `require`, `exports` and `module` definitions. (Necessary if libraries already defined this.)

## Callback

Has 2 arguments: `error` and `data`. Data is *string*. Can be empty string if defined *rollback* option.

## License

The MIT license.

Copyright (c) 2012 - 2015 Artem Yavorsky (http://yavorsky.org) & Hellyeah LLC (http://hellyeah.is).

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
