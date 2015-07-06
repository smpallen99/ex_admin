# quickly-copy-file

Quickly copy file from one path to another. No bullshit, ultra-simple, async and just one dep.

## Installation

`npm install quickly-copy-file`

## Usage

* `copyFile(fromPath, toPath, callback);` — `String`, `String`, `(optional) Function`
* `callback(error)` optionally receives error when the execution failed.

Node.js:

```javascript
var copyFile = require('quickly-copy-file');
copyFile('original.js', 'copy.js', function(error) {
  if (error) return console.error(error);
  console.log('File was copied!')
});
```

## License

The MIT License (MIT)

Copyright (c) 2015 Paul Miller (http://paulmillr.com/)

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
