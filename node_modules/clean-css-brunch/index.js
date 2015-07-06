var CleanCSS = require('clean-css');
var sysPath = require('path');

function CleanCSSMinifier(config) {
  if (config == null) config = {};
  var plugins = config.plugins
  if (plugins == null) plugins = {};
  this.options = plugins.cleancss;
}

CleanCSSMinifier.prototype.brunchPlugin = true;
CleanCSSMinifier.prototype.type = 'stylesheet';

CleanCSSMinifier.prototype.optimize = function(data, path, callback) {
  var error, optimized;
  try {
    optimized = new CleanCSS(this.options).minify(data).styles;
  } catch (_error) {
    error = "CSS minify failed on " + path + ": " + _error;
  } finally {
    callback(error, optimized || data);
  }
};

module.exports = CleanCSSMinifier;
