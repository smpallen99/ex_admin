'use strict';

var fs;

try {
  fs = require('graceful-fs');
} catch (e) {
  fs = require('fs');
}

/**
 * Copy file `src` to `dest`
 *
 * @api public
 * @param {String} src
 * @param {String} dest
 * @param {Function} cb
 */
exports = module.exports = function (src, dest, cb) {
  function next(err) {
    if (!done) {
      done = true;
      read.destroy();
      write.destroy();
      cb(err);
    }
  }

  var done = false
    , read = fs.createReadStream(src)
    , write = fs.createWriteStream(dest);

  write
    .on('error', next)
    .on('close', next);

  read
    .on('error', next)
    .pipe(write);
};

// magic number.  number of bytes allowed to be read
// at a time.  we're limiting this, as memory overflows
// are likely to happen when reading large files
// synchronously.
var MAX_BUFFER = 1024;

/**
 * Synchronously copy file `src` to `dest`
 *
 * @api public
 * @param {String} src
 * @param {String} dest
 */
exports.sync = function (src, dest) {
  if (!fs.existsSync(src)) {
    throw new Error('no such file or directory: ' + src);
  }

  var buffer = new Buffer(MAX_BUFFER)
    , bytesRead = MAX_BUFFER
    , position = 0
    , read = fs.openSync(src, 'r')
    , write = fs.openSync(dest, 'w');

  while (bytesRead === MAX_BUFFER) {
    bytesRead = fs.readSync(read, buffer, 0, MAX_BUFFER, position);
    fs.writeSync(write, buffer, 0, bytesRead);
    position += bytesRead;
  }

  fs.closeSync(read);
  fs.closeSync(write);
};
