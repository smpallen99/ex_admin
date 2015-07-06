
# string-to-js

  Make plain text (HTML, CSS, JSON, etc) require()-able.

## Installation

   $ npm install string-to-js

## Example

tip.html:

```html
<div class="tip">
  <div class="tip-message"></div>
</div>
```

js:

```js

/**
 * Module dependencies.
 */

var fs = require('fs')
  , str2js = require('string-to-js')
  , read = fs.readFileSync;

var html = read('tip.html', 'utf8');
var js = str2js(html);
console.log(js);
```

output js string:

```js
module.exports = '<div class="tip">\n  <div class="tip-message">\'Message here\'</div>\n</div>';
```

## License 

(The MIT License)

Copyright (c) 2012 TJ Holowaychuk &lt;tj@vision-media.ca&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.