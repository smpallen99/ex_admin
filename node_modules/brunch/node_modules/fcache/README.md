# fcache

> `fs.readFile` cache for node.js build systems & watchers

## Usage

```
# Your watcher
var fcache = require('fcache');
watcher.on('change', function(path) {
  fcache.updateCache(path, function(error, data) {
    // Do some stuff
  });
});

# Later, in your plugin
fcache.readFile(path, function(error, data) {
  // Would use cached version.
});

```
