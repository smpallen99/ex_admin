var logger = require('./');

var delay = function(fn) {
  setTimeout(fn, 1000);
};

delay(function() {
  logger.log('Hello, loggy');
  delay(function() {
    logger.warn('Deprecated');
    delay(function() {
      logger.error('Stuff');
    });
  });
});
