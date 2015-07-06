## uglify-js-brunch
Adds [UglifyJS](https://github.com/mishoo/UglifyJS2) support to
[brunch](http://brunch.io).

The plugin will minify your javascript files.

## Usage
Install the plugin via npm with `npm install --save uglify-js-brunch`.

Or, do manual install:

* Add `"uglify-js-brunch": "x.y.z"` to `package.json` of your brunch app.
  Pick a plugin version that corresponds to your minor (y) brunch version.
* If you want to use git version of plugin, add
`"uglify-js-brunch": "git+ssh://git@github.com:brunch/uglify-js-brunch.git"`.

To specify uglifyjs options, use `config.plugins.uglify` object, for example:
```coffeescript
config =
  plugins:
    uglify:
      mangle: false
      compress:
        global_defs: 
          DEBUG: false
```

Joined files can be ignored and be passed-through, using 'ignored' option:

```coffeeescript
config =
  plugins:
    uglify:
      ignored: /non_minimize\.js/

```

## License

The MIT License (MIT)

Copyright (c) 2012-2014 Paul Miller (http://paulmillr.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
