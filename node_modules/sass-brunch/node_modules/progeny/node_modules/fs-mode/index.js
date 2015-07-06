'use strict';

var fs = require('fs');
var cbify = require('cbify');

function fsMode (altFs) {
	if (typeof altFs === 'string') altFs = require(altFs);
	return modeify({}, altFs)
}

function modeify (mod, fs) {
	var Sync = mod.Sync = {};
	var Async = mod.Async = {};
	Object.keys(fs).forEach(function(key) {
		var fn = fs[key];
		mod[key] = fn;
		if (key.slice(-4) === 'Sync' || typeof fn !== 'function') return;
		var fns = fs[key + 'Sync'];
		if (fns) {
			Sync[key] = cbify(fns);
			Async[key] = fn;
		}
	});
	return mod;
}

module.exports = modeify(fsMode, fs);
