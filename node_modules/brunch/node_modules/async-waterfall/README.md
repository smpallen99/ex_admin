# async-waterfall

Simple, isolated async waterfall module for JavaScript.

Runs an array of functions in series, each passing their results to the next in
the array. However, if any of the functions pass an error to the callback, the
next function is not executed and the main callback is immediately called with
the error.

For browsers and node.js.

## Installation
* Just include async-waterfall before your scripts.
* `npm install async-waterfall` if you’re using node.js.
* `component install es128/async-waterfall` if you’re using
[component(1)](https://github.com/component/component).
* `bower install async-waterfall` if you’re using
[Twitter Bower](http://bower.io).

## Usage

* `waterfall(tasks, optionalCallback);`
* **tasks** - An array of functions to run, each function is passed a
`callback(err, result1, result2, ...)` it must call on completion. The first
argument is an error (which can be null) and any further arguments will be
passed as arguments in order to the next task.
* **optionalCallback** - An optional callback to run once all the functions have
completed. This will be passed the results of the last task's callback.

##### Node.js:

```javascript
var waterfall = require('async-waterfall');
waterfall(tasks, callback);
```

##### Browser:

```javascript
// component(1)
var waterfall = require('async-waterfall');
waterfall(tasks, callback);

// Default:
window.asyncWaterfall(tasks, callback);
```

##### Tasks as Array of Functions

```javascript
waterfall([
  function(callback){
    callback(null, 'one', 'two');
  },
  function(arg1, arg2, callback){
    callback(null, 'three');
  },
  function(arg1, callback){
    // arg1 now equals 'three'
    callback(null, 'done');
  }
], function (err, result) {
  // result now equals 'done'
});
```

##### Derive Tasks from an Array.map

```javascript
waterfall(myArray.map(function (arrayItem) {
  return function (lastItemResult, nextCallback) {
    // same execution for each item in the array
    var itemResult = doThingsWith(arrayItem, lastItemResult);
    // results carried along from each to the next
    nextCallback(null, itemResult);
}}), function (err, result) {
  // final callback
});
```


## Acknowledgements
Hat tip to [Caolan McMahon](https://github.com/caolan) and
[Paul Miller](https://github.com/paulmillr), whose prior contributions this is
based upon.


## License

The MIT License (MIT)

Copyright (c) 2013 Elan Shanker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
