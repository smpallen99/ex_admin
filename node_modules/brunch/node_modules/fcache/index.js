var fs = require('fs');
var ver = require('./package.json').version.split('.').slice(0, 2).join('.');
var key = '_fcache_' + ver;

var cache = global[key] || Object.create(null);
global[key] = cache;

exports.readFile = function(path, callback) {
  if (path in cache) {
    callback(undefined, cache[path]);
  } else {
    fs.readFile(path, 'utf-8', callback);
  }
};

exports.updateCache = function(path, callback) {
  if (!callback) callback = Function.prototype;
  fs.readFile(path, 'utf-8', function(error, source) {
    if (error) return callback(error);
    cache[path] = source;
    callback(undefined, source)
  });
};

