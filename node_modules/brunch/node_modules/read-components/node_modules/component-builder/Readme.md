# builder.js

  Component build tool. This is the library that `component(1)` utilizes
  to perform component builds.

## Installation

    $ npm install component-builder

## API

### new Builder(dir)

  Creates a new `Builder` for the given component's `dir`:

```js
var Builder = require('component-builder');
var builder = new Builder('components/visionmedia-page');
```

### Builder#config

  The component's component.json contents as an object.

### Builder#addSourceURLs()

  Add "sourceURL" support, wrapping the module functions
  in `Function()` calls so that browsers may assign a
  name to the scripts to aid in debugging.

### Builder#addLookup(path)

  Append the given dependency lookup `path`. This lookup `path` is
  "global", thus it influences all dependency lookups.

### Builder#development()

  Include development dependencies.

### Builder#addFile(type, filename, val)

  Add a fabricated file of the given `type`, `filename`,
  and contents `val`. For example if you were translating
  a Stylus file to .css, or a Jade template to .js you may
  do something like:

```js
builder.addFile('scripts', 'view.js', 'compiled view js');
```

### Builder#ignore(name, [type])

  Ignore building `name`'s `type`, where `type` is "scripts" or "styles". When
  no `type` is given both are ignored, this includes dependencies of `name` as well.

```js
builder.ignore('visionmedia-page')
```

### Builder#build(fn)

  Perform the build and pass an object to `fn(err, obj)` containing
  the `.css` and `.js` properties.

### Builder#hook(name, fn)

  A build "hook" is like an event that lets you manipulate the build in process. For
  example you may use a hook to translate coffee script files to javascript automatically,
  or compile a template to javascript so that it may be loaded with `require()`, or use
  CSS pre-processors such as [rework](https://github.com/visionmedia/rework).
  
  Available hooks are:
  - `before scripts`
  - `before styles`

### Builder#use(fn)

  Give the builder a plugin to use. The `fn` args are `fn(builder [, done])`. If The plugin has async logic it should invoke the `done` callback as needed. Sync plugins should ignore this argument.

## Examples

### Basic build

  The follow demonstrates the most basic build you can possible do using
  this component builder implementation. A root component directory is
  passed to `new Builder`, followed by a `.build()` call which then responds
  with a `res` object containing the followign properties:

  - `.require` the require implementation script
  - `.js` compiled javascript
  - `.css` compiled css

```js
var builder = new Builder('lib/boot');

builder.build(function(err, res){
  if (err) throw err;
  console.log(res.require + res.js);
  console.log(res.css);
});
```

### Lookup paths

  In the previous example all the application's private components live in `./lib`,
  thus if you want to specify dependencies without a leading `"lib/"` a lookup path
  should be created with `.addLookup()`:

```js
var builder = new Builder('lib/boot');

builder.addLookup('lib');
...
```

## License

  MIT
