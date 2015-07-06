var esprima = require('esprima');

function JavaScriptCompiler(brunchCfg) {
  var config = brunchCfg && brunchCfg.plugins && brunchCfg.plugins.javascript;
  this.validate = (config && config.validate);
  if (this.validate == null) this.validate = true;
}
JavaScriptCompiler.prototype.brunchPlugin = true;
JavaScriptCompiler.prototype.type = 'javascript';
JavaScriptCompiler.prototype.extension = 'js';
JavaScriptCompiler.prototype.compile = function(params, callback) {
  if (this.validate) {
    try {
      var errors = esprima.parse(params.data, {tolerant: true}).errors.map(function(error) {
        return error.message;
      });
      if (errors.length) return callback(errors);
    } catch (error) {
      return callback(error);
    }
  }

  return callback(null, params);
};

module.exports = JavaScriptCompiler;
