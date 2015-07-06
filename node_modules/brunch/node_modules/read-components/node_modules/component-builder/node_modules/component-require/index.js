
var fs = require('fs')
  , read = fs.readFileSync;

module.exports = read(__dirname + '/lib/require.js', 'utf8');