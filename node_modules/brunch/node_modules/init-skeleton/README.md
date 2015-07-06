# init-skeleton

A simple interface that clones or copies skeletons.
skeleton is a base repo for your application (any technology).

`init-skeleton` currently just clones or copies the repository,
executes `npm install` and `bower install` and removes `.git` directory.
Useful for [Brunch](http://brunch.io) and
[Grunt](http://gruntjs.com) base repos (skeletons).

[grunt-init](https://github.com/gruntjs/grunt-init) is similar, except it
requires to clone projects to home directory before initialising from it.

Supported formats:

* File system
* Git URI
* GitHub URI (gh:user/project, github:user/project)

Install with npm: `npm install init-skeleton`.

## Usage

initSkeleto

```javascript
var initSkeleton = require('init-skeleton');

initSkeleton('skeleton', function(error) {
  console.log('Cloned');
});
```

- options:
    - `rootPath` - `String`, root path of the result directory
    - `commandName`: `String`
    - `logger`: `console.{log,error}`-compatible logger.


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
