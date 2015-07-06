var fs = require('fs');
var sysPath = require('path');

module.exports = fs.readFileSync(sysPath.join(__dirname, 'require.js'), 'utf8');
