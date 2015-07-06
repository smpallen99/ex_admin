'use strict';

var define = require('define-properties');

/* http://www.ecma-international.org/ecma-262/6.0/#sec-number.isnan */

var numberIsNaN = function isNaN(value) {
	return value !== value;
};

define(numberIsNaN, {
	shim: function shimNumberIsNaN() {
		if (!Number.isNaN) {
			define(Number, { isNaN: numberIsNaN });
		}
		return Number.isNaN || numberIsNaN;
	}
});

module.exports = numberIsNaN;
