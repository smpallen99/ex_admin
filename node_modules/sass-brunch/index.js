var cp = require('child_process'), spawn = cp.spawn, exec = cp.exec;
var sysPath = require('path');
var progeny = require('progeny');
var libsass = require('node-sass');
var Promise = require('promise');
var os = require('os');
var util = require('util');

var isWindows = os.platform() === 'win32';
var compassRe = /compass/;
var sassRe = /\.sass$/;

var extend = function(object, source) {
  for (var key in source) object[key] = source[key];
  return object;
};

function SassCompiler(cfg) {
  if (cfg == null) cfg = {};
  this.rootPath = cfg.paths.root;
  this.optimize = cfg.optimize;
  this.config = (cfg.plugins && cfg.plugins.sass) || {};
  this.mode = this.config.mode;
  if (this.config.options != null && this.config.options.includePaths != null) {
    this.includePaths = this.config.options.includePaths;
  }
  this.getDependencies = progeny({
    rootPath: this.rootPath,
    altPaths: this.includePaths,
    reverseArgs: true
  });
  this.seekCompass = progeny({
    rootPath: this.rootPath,
    exclusion: '',
    potentialDeps: true
  });
  this.gem_home = this.config.gem_home;
  this.env = {};
  if (this.gem_home) {
    var env = extend({}, process.env);
    env.GEM_HOME = this.gem_home;
    this.env = {
      env: env
    };
    this._bin = this.gem_home + "/bin/" + this._bin;
    this._compass_bin = this.gem_home + "/bin/" + this._compass_bin;
  }
  this.bundler = this.config.useBundler;
  this.prefix = this.bundler ? 'bundle exec ' : '';
}

SassCompiler.prototype.brunchPlugin = true;
SassCompiler.prototype.type = 'stylesheet';
SassCompiler.prototype.extension = 'scss';
SassCompiler.prototype.pattern = /\.s[ac]ss$/;
SassCompiler.prototype._bin = isWindows ? 'sass.bat' : 'sass';
SassCompiler.prototype._compass_bin = isWindows ? 'compass.bat' : 'compass';

SassCompiler.prototype._checkRuby = function() {
  var prefix = this.prefix;
  var env = this.env;
  var sassCmd = this.prefix + this._bin + " --version";
  var compassCmd = this.prefix + this._compass_bin + " --version";

  var sassPromise = new Promise(function(resolve, reject) {
    exec(sassCmd, env, function(error) {
      if (error) {
        console.error("You need to have Sass on your system");
        console.error("Execute `gem install sass`");
        reject();
      } else {
        resolve();
      }
    });
  });
  var compassPromise = new Promise((function(resolve, reject) {
    exec(compassCmd, env, (function(error) {
      this.compass = !error;
      resolve();
    }).bind(this));
  }).bind(this));
  this.rubyPromise = Promise.all([sassPromise, compassPromise]);
};

SassCompiler.prototype._getIncludePaths = function(path) {
  var includePaths = [this.rootPath, sysPath.dirname(path)];
  if (Array.isArray(this.includePaths)) {
    includePaths = includePaths.concat(this.includePaths);
  }
  return includePaths;
};

SassCompiler.prototype._nativeCompile = function(source, callback) {
  libsass.render({
    data: source.data,
    success: (function(data) {
      if(data.css) data = data.css;
      callback(null, data);
    }),
    error: (function(error) {
      callback(error.message || util.inspect(error));
    }),
    includePaths: this._getIncludePaths(source.path),
    outputStyle: 'nested',
    sourceComments: !this.optimize
  });
};

SassCompiler.prototype._rubyCompile = function(source, callback) {
  if (this.rubyPromise == null) this._checkRuby();
  var result = '';
  var error = null;
  var cmd = [
    this._bin,
    '--stdin'
  ];

  var includePaths = this._getIncludePaths(source.path);
  includePaths.forEach(function(path) {
    cmd.push('--load-path');
    cmd.push(path);
  });
  if (!this.config.allowCache) cmd.push("--no-cache");

  if (this.bundler) cmd.unshift('bundle', 'exec');

  this.rubyPromise.then((function() {
    var debugMode = this.config.debug, hasComments;
    if ((debugMode === 'comments' || debugMode === 'debug') && !this.optimize) {
      hasComments = this.config.debug === 'comments';
      cmd.push(hasComments ? '--line-comments' : '--debug-info');
    }

    if (!sassRe.test(source.path)) cmd.push('--scss');
    if (source.compass && this.compass) cmd.push('--compass');
    if (this.config.options != null) cmd.push.apply(cmd, this.config.options);

    if (isWindows) {
      cmd = ['cmd', '/c', '"' + cmd[0] + '"'].concat(cmd.slice(1));
      this.env.windowsVerbatimArguments = true;
    }
    var sass = spawn(cmd[0], cmd.slice(1), this.env);
    sass.stdout.on('data', function(buffer) {
      result += buffer.toString();
    });
    sass.stderr.on('data', function(buffer) {
      if (error == null) error = '';
      error += buffer.toString();
    });
    sass.on('close', function(code) {
      callback(error, result);
    });
    if (sass.stdin.write(source.data)) {
      sass.stdin.end();
    } else {
      sass.stdin.on('drain', function() {
        sass.stdin.end();
      });
    }
  }).bind(this));
};

SassCompiler.prototype.compile = function(data, path, callback) {
  // skip empty source files
  if (!data.trim().length) return callback(null, '');

  this.seekCompass(path, data, (function (err, imports) {
    if (err) callback(err);

    var source = {
      data: data,
      path: path,
      compass: imports.some(function (depPath){
        return compassRe.test(depPath);
      })
    };

    var fileUsesRuby = sassRe.test(path) || source.compass;

    if (this.mode === 'ruby' || (this.mode !== 'native' && fileUsesRuby)) {
      this._rubyCompile(source, callback);
    } else {
      this._nativeCompile(source, callback);
    }
  }).bind(this));
};

module.exports = SassCompiler;
