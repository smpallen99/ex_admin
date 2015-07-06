# pushserve

Dead-simple node.js pushState-enabled command-line http server.

## Usage

* Install it with `npm`: `npm install -g pushserve`.
* Launch: `pushserve`.
    * You may specify port (default is 8000): `pushserve --port 4567`.

```
  Usage: pushserve [options]

  Options:

    -h, --help              output usage information
    -V, --version           output the version number
    -p, --port <port>       Web server port [8000]
    -P, --path <path>       Path [.]
    -i, --indexPath <path>  Path to file which to which 404s will be redirected [index.html]
    -c, --noCors            Disable cross-origin resource sharing
    -s, --noPushstate       Disable pushState
```

Node.js API:

```javascript
var pushserve = require('pushserve');
// Any of these ways.
pushserve();
pushserve(function(error, options) {
  console.log('Launched');
});
pushserve({port: 4567, indexPath: '../index.html', noCors: true});
pushserve({port: 5555}, function() {
  console.log('Launched');
});
```

Additionally, node.js API also adds `noLog` option with which
default server start message won’t be printed.

You can stop the server in node with `var server = pushserve(); server.close();`.

## License

The MIT License (MIT)

Copyright (c) 2013 Paul Miller (http://paulmillr.com/)

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
