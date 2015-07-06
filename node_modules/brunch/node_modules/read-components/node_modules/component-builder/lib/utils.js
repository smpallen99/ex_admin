
/**
 * Strip `str` quotes.
 *
 * @param {String} str
 * @return {String}
 * @api private
 */

exports.stripQuotes = function(str) {
  if ('"' == str[0] || "'" == str[0]) return str.slice(1, -1);
  return str;
};

/**
 * Normalize `conf`.
 *
 * @param {Object} conf
 * @api private
 */

exports.normalizeConfig = function(conf){
  // support "./" in main
  if (conf.main) conf.main = conf.main.replace(/^\.\//, '');
};
