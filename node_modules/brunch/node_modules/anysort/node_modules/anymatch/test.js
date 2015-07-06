'use strict';

var anymatch = require('./');
var assert = require('assert');

describe('anymatch', function() {
  var matchers = [
    'path/to/file.js',
    'path/anyjs/**/*.js',
    /foo.js$/,
    function(string) {
      return string.indexOf('bar') !== -1 && string.length > 10;
    }
  ];
  it('should resolve string matchers', function() {
    assert(anymatch(matchers, 'path/to/file.js'));
    assert(anymatch(matchers[0], 'path/to/file.js'));
    assert(!anymatch(matchers[0], 'bar.js'));
  });
  it('should resolve glob matchers', function() {
    assert(anymatch(matchers, 'path/anyjs/baz.js'));
    assert(anymatch(matchers[1], 'path/anyjs/baz.js'));
    assert(!anymatch(matchers[1], 'bar.js'));
  });
  it('should resolve regexp matchers', function() {
    assert(anymatch(matchers, 'path/to/foo.js'));
    assert(anymatch(matchers[2], 'path/to/foo.js'));
    assert(!anymatch(matchers[2], 'bar.js'));
  });
  it('should resolve function matchers', function() {
    assert(anymatch(matchers, 'path/to/bar.js'));
    assert(anymatch(matchers[3], 'path/to/bar.js'));
    assert(!anymatch(matchers[3], 'bar.js'));
  });
  it('should return false for unmatched strings', function() {
    assert(!anymatch(matchers, 'bar.js'));
  });
  it('should ignore improperly typed matchers', function() {
    var emptyObj;
    emptyObj = {};
    assert(!anymatch(emptyObj, emptyObj));
    assert(!anymatch(Infinity, Infinity));
  });
  describe('with returnIndex = true', function() {
    it('should return the array index of first positive matcher', function() {
      var result;
      result = anymatch(matchers, 'foo.js', true);
      assert.equal(result, 2);
    });
    it('should return 0 if provided non-array matcher', function() {
      var result;
      result = anymatch(matchers[2], 'foo.js', true);
      assert.equal(result, 0);
    });
    it('should return -1 if no match', function() {
      var result;
      result = anymatch(matchers, 'bar.js', true);
      assert.equal(result, -1);
    });
  });

  describe('curried matching function', function() {
    var matchFunc;
    matchFunc = anymatch(matchers);
    it('should resolve matchers', function() {
      assert(anymatch(matchers, 'path/to/file.js'));
      assert(anymatch(matchers, 'path/anyjs/baz.js'));
      assert(anymatch(matchers, 'path/to/foo.js'));
      assert(anymatch(matchers, 'path/to/bar.js'));
      assert(!anymatch(matchers, 'bar.js'));
    });
    it('should be usable as an Array.prototype.filter callback', function() {
      var arr, expected;
      arr = ['path/to/file.js', 'path/anyjs/baz.js', 'path/to/foo.js', 'path/to/bar.js', 'bar.js', 'foo.js'];
      (expected = arr.slice()).splice(arr.indexOf('bar.js'), 1);
      assert.deepEqual(arr.filter(matchFunc), expected);
    });
  });

  describe('using matcher subsets', function() {
    it('should skip matchers before the startIndex', function() {
      assert(anymatch(matchers, 'path/to/file.js', false));
      assert(!anymatch(matchers, 'path/to/file.js', false, 1));
    });
    it('should skip matchers after and including the endIndex', function() {
      assert(anymatch(matchers, 'path/to/bars.js', false));
      assert(!anymatch(matchers, 'path/to/bars.js', false, 0, 3));
      assert(!anymatch(matchers, 'foo.js', false, 0, 1));
    });
  });
});
