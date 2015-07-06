'use strict';

var fs = require('fs');
var dirname = require('path').dirname;
var mkdirp = require('mkdirp');

var copyCounter = 0;
var copyQueue = [];
var emptyFn = Function.prototype;

var copyFile = function(source, destination, callback) {
  if (callback == null) callback = emptyFn;

  var attempt = function(error, retries) {
    if (retries == null) retries = 0;
    if (error != null) return callback(error);

    copyCounter++;

    var instanceError = false;
    var onError = function(err) {
      if (instanceError) return;
      instanceError = true;
      copyCounter--;
      if (retries >= 5) return callback(err);
      var code = err.code;
      if (code === 'OK' || code === 'UNKNOWN' || code === 'EMFILE') {
        copyQueue.push(function() { attempt(null, ++retries); });
      } else if (code === 'EBUSY') {
        var timeout = 100 * ++retries;
        setTimeout(function() { attempt(null, retries); }, timeout);
      } else {
        callback(err);
      }
    };

    var onClose = function() {
      if (--copyCounter < 1 && copyQueue.length) {
        var nextFn = copyQueue.shift();
        process.nextTick(nextFn);
      }
      onClose = emptyFn;
      callback();
    };

    var input = fs.createReadStream(source);
    var output = input.pipe(fs.createWriteStream(destination));
    input.on('error', onError);
    output.on('error', onError);
    output.on('close', onClose);
    output.on('finish', onClose);
  };

  var parentDir = dirname(destination);
  fs.exists(parentDir, function(exists) {
    if (!exists) return mkdirp(parentDir, attempt);
    if (copyQueue.length) {
      copyQueue.push(attempt);
    } else {
      attempt();
    }
  });
};

module.exports = copyFile;
