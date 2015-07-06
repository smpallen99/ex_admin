# Sass Graph

Parses sass and exposes a graph of dependencies

[![Build Status](https://travis-ci.org/xzyfer/sass-graph.svg?branch=master)](https://travis-ci.org/xzyfer/sass-graph)
[![npm version](https://badge.fury.io/js/sass-graph.svg)](http://badge.fury.io/js/sass-graph)
[![Dependency Status](https://david-dm.org/xzyfer/sass-graph.svg?theme=shields.io)](https://david-dm.org/xzyfer/sass-graph)
[![devDependency Status](https://david-dm.org/xzyfer/sass-graph/dev-status.svg?theme=shields.io)](https://david-dm.org/xzyfer/sass-graph#info=devDependencies)

## Install

Install with [npm](https://npmjs.org/package/sass-graph)

```
npm install --save-dev sass-graph
```

## Usage

Usage as a Node library:

```js
$ node
> var sassGraph = require('./sass-graph');
undefined
> sassGraph.parseDir('tests/fixtures');
{ index: {,
    'tests/fixtures/a.scss': {
        imports: ['b.scss'],
        importedBy: [],
    },
    'tests/fixtures/b.scss': {
        imports: ['_c.scss'],
        importedBy: ['a.scss'],
    },
    'tests/fixtures/_c.scss': {
        imports: [],
        importedBy: ['b/scss'],
    },
}}
```

Usage as a command line tool:

The command line tool will parse a graph and then either display ancestors, descendents or both.

```
$ ./bin/sassgraph tests/fixtures tests/fixtures/a.scss -d
tests/fixtures/a.scss
tests/fixtures/b.scss
tests/fixtures/_c.scss
```

## Running Mocha tests

You can run the tests by executing the following commands:

```
npm install
npm test
```

## Authors

Sass graph was originally written by [Lachlan Donald](http://lachlan.me).
It is now maintained by [Michael Mifsud](http://twitter.com/xzyfer).

## License

MIT
