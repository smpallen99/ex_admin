'use strict';
var color = require('ansi-color');
var growl = require('growl');
require('date-utils');

var slice = [].slice;

var capitalize = function(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
};

var logger = {
  // Format of date in logs.
  entryFormat: 'DD MMM HH24:MI:SS',

  // Enables / disables system notifications for errors.
  notifications: true,

  // Colors that will be used for various log levels.
  colors: {
    error: 'red',
    warn: 'yellow',
    info: 'green',
    log: 'green',
    success: 'green'
  },

  // May be used for setting correct process exit code.
  errorHappened: false,

  // Creates new colored log entry.
  // Example:
  //
  //     format('warn')
  //     # => 21 Feb 11:24:47 - warn:
  //
  // Returns String.
  format: function(level, entryFormat) {
    var date = new Date().toFormat(entryFormat || logger.entryFormat);
    var colored = logger.colors ? color.set(level, logger.colors[level]) : level;
    return '' + date + ' - ' + colored + ':';
  },

  _notify: function(level, args) {
    if (level === 'error') logger.errorHappened = true;

    var notifSettings = logger.notifications;
    var types = logger._notificationTypes;
    var title = logger._title;

    if (!types) {
      types = logger._notificationTypes = {};

      if ('notifications' in logger) {
        if (typeof notifSettings === 'object') {
          notifSettings.forEach(function(name) {
            types[name] = true;
          });
        } else {
          types.error = true;
        }
      }
    }

    if (title == null) {
      title = logger._title = logger.notificationsTitle ?
        logger.notificationsTitle + ' ' : '';
    }

    if (types[level]) {
      growl(args.join(' '), {title: title + capitalize(level)});
    }
  },

  _log: function(level, args) {
    var entry = logger.format(level);
    var all = [entry].concat(args);

    if (level === 'error' || level === 'warn') {
      console.error.apply(console, all);
    } else {
      console.log.apply(console, all);
    }
  }
};

['error', 'warn', 'info', 'log', 'success'].forEach(function(key) {
  logger[key] = function() {
    var args = slice.call(arguments);
    logger._notify(key, args);
    logger._log(key, args);
  }
});

module.exports = logger;
