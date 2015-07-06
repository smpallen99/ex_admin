'use strict';

var wrappy = require('wrappy');
var fnArgs = require('fn-args');

module.exports = wrappy(function cbify (fn) {
	if (typeof fn !== 'function') {
		throw new TypeError('Expected a function');
	}

	var origArgs = fnArgs(fn);
	var lastArg = origArgs[origArgs.length - 1];

	if (
		origArgs.length &&
		lastArg.toLowerCase().indexOf('callback') !== -1 ||
		lastArg === 'cb'
	) {
		return fn;
	}

	return function () {
		var argsLen = arguments.length;
		var args = argsLen > 1 ? [].slice.call(arguments, 0, argsLen - 1) : [];
		var callback = arguments[argsLen - 1];
		var result;

		if (typeof callback !== 'function') {
			throw new Error('Must pass callback function');
		}

		try {
			result = fn.apply(this, args);
		} catch (_err) {
			result = _err;
		} finally {
			if (result instanceof Error) {
				callback(result);
			} else {
				callback(null, result);
			}
		}

	};
});
