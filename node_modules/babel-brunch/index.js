'use strict';

var babel = require('babel-core');
var anymatch = require('anymatch');

function BabelCompiler(config) {
  if (!config) config = {};
  var options = config.plugins &&
    (config.plugins.babel || config.plugins.ES6to5) || {};
  this.options = {};
  Object.keys(options).forEach(function(key) {
    if (key === 'sourceMap' || key === 'ignore') return;
    this.options[key] = options[key];
  }, this);
  this.options.sourceMap = !!config.sourceMaps;
  this.isIgnored = anymatch(options.ignore || /^(bower_components|vendor)/);
  if (this.options.pattern) {
    this.pattern = this.options.pattern;
    delete this.options.pattern;
  }
}

BabelCompiler.prototype.brunchPlugin = true;
BabelCompiler.prototype.type = 'javascript';
BabelCompiler.prototype.extension = 'js';

BabelCompiler.prototype.compile = function (params, callback) {
  if (this.isIgnored(params.path)) return callback(null, params);
  this.options.filename = params.path;
  var compiled;
  try {
    compiled = babel.transform(params.data, this.options);
  } catch (err) {
    return callback(err);
  }
  var result = {data: compiled.code || compiled};

  // Concatenation is broken by trailing comments in files, which occur
  // frequently when comment nodes are lost in the AST from babel.
  result.data += '\n';

  if (compiled.map) result.map = JSON.stringify(compiled.map);
  callback(null, result);
};

module.exports = BabelCompiler;
