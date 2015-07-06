
module.exports = process.env.CP_COV
  ? require('./lib-cov/cp')
  : require('./lib/cp');
