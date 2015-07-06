anysort [![Build Status](https://travis-ci.org/es128/anysort.svg)](https://travis-ci.org/es128/anysort) [![Coverage Status](https://img.shields.io/coveralls/es128/anysort.svg)](https://coveralls.io/r/es128/anysort)
=======
Javascript module to sort arrays of strings using flexible arrays of matchers.
Regular expressions, globs, plain strings, or functions may be used as matchers
([see anymatch](https://github.com/es128/anymatch)).

[![NPM](https://nodei.co/npm/anysort.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/anysort/)
[![NPM](https://nodei.co/npm-dl/anysort.png?height=3&months=9)](https://nodei.co/npm-dl/anysort/)

Usage
-----
```sh
npm install anysort --save
```

#### anysort ([a, b,] [matchers])
Intended for use in an [`Array.sort`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort)
callback. `matchers` is an array of [anymatch](https://github.com/es128/anymatch)
compatible matchers.`a` and `b` are two values to be compared. If called with
only `matchers`, returns a function (the `Array.sort` callback). If `matchers`
is omitted, the array will be sorted naturally (alphabetically). Natural sort
will also be used in case of a tie (multiple members matching the same matcher).

```js
var anysort = require('anysort');

var unsorted = [
	'path/to/foo.js',
	'path/to/bar.js',
	'bar.js',
	'path/anyjs/baz.js',
	'path/anyjs/aaz.js',
	'path/to/file.js'
	'path/anyjs/caz.js',
];

var matchers = [
	'path/to/file.js',
	'path/anyjs/**/*.js',
	/foo.js$/,
	function (string) {
		return string.indexOf('bar') !== -1 && string.length > 10
	}
];

// the following two are equivalent
unsorted.sort(anysort(matchers));

unsorted.sort(function (a, b){
	// except there is an opportunity to run your own
	// operations/mutations on a and b here if needed
	return anysort(a, b, matchers);
});
/*
[ 'path/to/file.js',
	'path/anyjs/aaz.js',
	'path/anyjs/baz.js',
	'path/anyjs/caz.js',
	'path/to/foo.js',
	'path/to/bar.js',
	'bar.js' ]
*/
```

#### anysort.splice (list, [matchers], [tieBreakers])
Sorts the whole array. Returns an object with `sorted`, `matched`, and
`unmatched` properties. `matched` is a sorted array of the `list` members that
matched any of the `matchers`. `unmatched` is an array of the `list` members
that didn't match any `matchers`, sorted natively. `sorted` is a concatenation
of `matched` and `unmatched`. `tieBreakers` can optionally be specified as a 
second set of matchers which will not cause inclusion in the `matched` set, but
will be used for fallback sorting in case of ties caused by multiple `list`
array members matching the same matcher. `tieBreakers` must be an array.

```js
anysort.splice(unsorted, matchers);
/*
{ matched:
	 [ 'path/to/file.js',
		 'path/anyjs/aaz.js',
		 'path/anyjs/baz.js',
		 'path/anyjs/caz.js',
		 'path/to/foo.js',
		 'path/to/bar.js' ],
	unmatched: [ 'bar.js' ],
	sorted:
	 [ 'path/to/file.js',
		 'path/anyjs/aaz.js',
		 'path/anyjs/baz.js',
		 'path/anyjs/caz.js',
		 'path/to/foo.js',
		 'path/to/bar.js',
		 'bar.js' ] }
*/

// quick access to just the sorted array
anysort.splice(unsorted, matchers).sorted;
```

#### anysort.grouped (list, [groupedMatchers], [order])
Allows use of an array of matcher arrays and arbitrary placement of the
unmatched list members, which is useful if you want to define some to definitely
go at the bottom. Also, can be used to create exclusion sets.

`groupedMatchers` should be put in order of priority (in case a `list` member
might match multiple). Include the string `'unmatched'` as a top-level member of
`groupedMatchers` to set the position of any members that do not match any
matchers, otherwise it is assumed to belong at the end. `groupedMatchers` also
sets the order of results, unless an `order` array is defined to override it. If
an `order` is provided that omits any of the indexes from `groupedMatchers`, the
corresponding matches will be excluded from the output.

```js
var before = /to/;
var after = ['path/anyjs/baz.js', 'path/anyjs/aaz.js'];
anysort.grouped(unsorted, [before, 'unmatched', after]);
/*
[ 'path/to/bar.js',
	'path/to/file.js',
	'path/to/foo.js',
	'bar.js',
	'path/anyjs/caz.js',
	'path/anyjs/baz.js',
	'path/anyjs/aaz.js' ]
*/

var exclusions = /anyjs/;
// 2 is the index for unmatched list members
anysort.grouped(unsorted, [exclusions, matchers], [2, 1]);
/*
[ 'bar.js',
	'path/to/file.js',
	'path/to/foo.js',
	'path/to/bar.js' ]
*/
```

Change Log
----------
[See release notes page on GitHub](https://github.com/es128/anymatch/releases)

License
-------
[ISC](https://raw.github.com/es128/anysort/master/LICENSE)
