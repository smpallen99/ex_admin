var sysPath = require('path');
var uglify = require('uglify-js');

var extend = function(object, source) {
  var value;
  for (var key in source) {
    value = source[key];
    object[key] = (typeof value === 'object' && !(value instanceof RegExp)) ?
      (Array.isArray(value) ? value.slice() : extend({}, value)) :
      value;
  }
  return object;
};

function UglifyJSOptimizer(config) {
  if (config == null) config = {};
  var options = config.plugins && config.plugins.uglify;
  this.options = options ? extend({}, options) : {};
  this.options.fromString = true;
  this.options.sourceMaps = !!config.sourceMaps;
}

UglifyJSOptimizer.prototype.brunchPlugin = true;
UglifyJSOptimizer.prototype.type = 'javascript';

UglifyJSOptimizer.prototype.optimize = function(args, callback) {
  var error, optimized, data, path;
  data = args.data;
  path = args.path;

  try {
    if (this.options.ignored && this.options.ignored.test(args.path)) {
      // ignored file path: return non minified
      var result = {
        data: data,
        // It seems like brunch passes in a SourceMapGenerator object, not a string
        map: args.map ? args.map.toString() : null
      };
      return callback(null, result);
    }
  } catch (e) {
    return callback('error checking ignored files to uglify' + e);
  }

  try {
    this.options.inSourceMap = JSON.parse(args.map);
  } catch (_e) {}

  this.options.outSourceMap = this.options.sourceMaps ?
    path + '.map' : undefined;

  try {
    optimized = uglify.minify(data, this.options);
  } catch (_error) {
    error = 'JS minification failed on ' + path + ': ' + _error;
  } finally {
    if (error) return callback(error);
    var result = optimized && this.options.sourceMaps ? {
      data: optimized.code,
      map: optimized.map
    } : {data: optimized.code};
    result.data = result.data.replace(/\n\/\/# sourceMappingURL=\S+$/, '');
    callback(null, result);
  }
};

module.exports = UglifyJSOptimizer;
