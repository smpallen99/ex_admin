# cbify

Wraps synchronous functions with a callback-style API so they can match their
async brethren. 

Useful for handling both sync and async methods with the same underlying code.
Preserves the sync-ness of the original function, making it possible to use
values passed to the callback as a return value.

## Install

**npm**
```sh
npm install --save cbify
```

**Bower**
```sh
bower install --save cbify
```
The browser build for bower includes a UMD wrapper which adapts to various
module systems, or exposes a `cbify` global if none are present.

**Duo**
```js
var cbify = require('es128/cbify')
```

## Usage

```js
var cbify = require('cbify');

var sum = cbify(function (a, b) {
	return a + b;
});

var answer;
sum(32, 96, function (err, result) {
	answer = result;
});

console.log(answer); // 128
// would have been undefined if `sum` had handled the callback asynchronously
```

If provided a function whose last named argument is `cb` or `callback` (or even
if it just contains `callback`), then that function will be returned unchanged.

The `this` context the cbify'd function is called with will be preserved
for the underlying function. Feel free to use `bind`, `apply`, etc as you would
have before implementing cbify.

## Similar modules

I was surprised I couldn't find a pre-existing module that did this. I did find
a few that almost did it, but were ruled out for slight differences.

* [__sinless__](https://github.com/thlorenz/sinless):
  Uses `setImmediate`, causing the wrapped function to always return
  asynchronously, even though the underlying method may still be blocking.
* [__ifyify__](https://github.com/Tarabyte/ifyify):
  The `callbackify` method provided by this module is only different in that it
  wraps the function with a continuation-style API, meaning that `err` will now
  always be the first argument.
* [__wrap-fn__](https://github.com/MatthewMueller/wrap-fn):
  Another API style. Expects the callback at the time the function is being
  wrapped so the resulting function signature stays the same.

## What about [Z͡alg̨ó](http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony)?

This makes synchronous functions pass their result to a callback synchronously.
It's an important feature of this module, providing the ability to adapt some
async APIs to also provide a sync option with minimal code changes. This is
done knowingly and is consistent, so it does not release Zalgo. 

However, you do have to be careful for ͟h͞e͘ ̢Wa͜it̛s̨ ͡B̨e͡h̛in̨d ͠The̷ W͏a͝l͏ĺ.
If you do not know whether the functions you're passing into cbify are sync or
async, and you are otherwise treating them identically, then you may be
́un͘l͜͝e҉a͟҉̨sh̕i̶͜҉n͏̧̕g̢̕ ̧T̷͞ḩe͟ ͜N̢̛͢e̛͟͠z̨͟ṕ̵̨e͟͡͏r̡̀d̨i̧̧a̢͢n ̡hi҉͜v̷e͢-̡͘͘mi̵͞nd̀ 
̡of̀ ͢͝cḩ̕a̶̶o̷͜s͘͞.҉͝. In that case, you may want to use
[sinless](https://github.com/thlorenz/sinless) instead, or use cbify together
with [dezalgo](https://github.com/npm/dezalgo).

## License

[ISC](https://raw.github.com/es128/cbify/master/LICENSE)
