var sysPath = require('path');
var fs = require('fs');
var each = require('async-each');
var events = require('events');
var emitter = new events.EventEmitter();

var jsonPaths = {
  bower: 'bower.json',
  dotbower: '.bower.json',
  component: 'component.json'
};

var dependencyLocator = {
  bower: 'name',
  component: 'repo'
};

var Builder = require('component-builder');

var jsonProps = ['main', 'scripts', 'styles'];

var getDir = function(root, type, callback) {
  if (type == 'bower') {
    var defaultBowerDir = 'bower_components';
    var bowerrcPath = sysPath.join(root, '.bowerrc');

    fs.exists(bowerrcPath, function(hasBowerrc) {
      if (hasBowerrc) {
        fs.readFile(bowerrcPath, 'utf8', function(error, bowerrcContent) {
          if (error) return callback(error);

          var bowerrcJson = JSON.parse(bowerrcContent);
          var bowerrcDirectory = bowerrcJson.directory;
          callback(null, bowerrcDirectory || defaultBowerDir);
        });
      } else {
        callback(null, defaultBowerDir);
      }
    });
  } else if (type == 'component') {
    return callback(null, 'components');
  } else {
    return callback(null);
  }
};

// Return unique list items.
var unique = function(list) {
  return Object.keys(list.reduce(function(obj, _) {
    if (!obj[_]) obj[_] = true;
    return obj;
  }, {}));
};

var sanitizeRepo = function(repo) {
  if (repo.indexOf('/') !== repo.lastIndexOf('/')) {
    var res = repo.split('/');
    return res[res.length-1] + '=' + res[res.length];
  }
  return repo.replace('/', '-');
}

/*var resolveComponent = function(name) {
  return name.replace('/', '-');
};*/

var readJson = function(file, type, callback) {
  fs.exists(file, function(exists) {
    if (!exists) {
      var err = new Error('Component must have "' + file + '"');
      err.code = 'NO_'+ type.toUpperCase() +'_JSON';
      return callback(err);
    };

    fs.readFile(file, function(err, contents) {
      if (err) return callback(err);

      var json;

      try {
        json = JSON.parse(contents.toString());
      } catch(err) {
        err.code = 'EMALFORMED';
        return callback(new Error('Component JSON file is invalid in "' + file + '": ' + err));
      }

      callback(null, json);
    });
  });
};

var getJsonPath = function(path, type) {
  return sysPath.resolve(sysPath.join(path, jsonPaths[type]));
};

// Coerce data.main, data.scripts and data.styles to Array.
var standardizePackage = function(data) {
  if (data.main && !Array.isArray(data.main)) data.main = [data.main];
  jsonProps.forEach(function(_) {
    if (!data[_]) data[_] = [];
  });
  return data;
};

var getPackageFiles = exports.getPackageFiles = function(pkg) {
  var list = [];
  jsonProps.forEach(function(property) {
    Array.isArray(pkg[property]) && list.push.apply(list, pkg[property]);
  });
  return unique(list);
};

var processPackage = function(type, pkg, callback) {
  var path = pkg.path;
  var overrides = pkg.overrides;
  var fullPath = getJsonPath(path, type);
  var dotpath = getJsonPath(path, 'dotbower');
  
  var _read = function(actualPath) {
    readJson(actualPath, type, function(error, json) {
      
      if (error) return callback(error);
      if (overrides) {
        Object.keys(overrides).forEach(function(key) {
          json[key] = overrides[key];
        });
      }

      if (type === 'bower' && !json.main) {
        return callback(new Error('Component JSON file "' + actualPath + '" must have `main` property. See https://github.com/paulmillr/read-components#README'));
      }

      var pkg = standardizePackage(json);


      var files = getPackageFiles(pkg).map(function(relativePath) {
        return sysPath.join(path, relativePath);
      });

      callback(null, {
        name: pkg.name, version: pkg.version, repo: sysPath.basename(path),
        files: files, dependencies: pkg.dependencies || {}
      });
    });
  };
  fs.exists(dotpath, function(isStableBower) {
    _read(isStableBower ? dotpath : fullPath)
  });
};

var gatherDeps = function(packages, type) {
  return Object.keys(packages.reduce(function(obj, item) {
    if (!obj[item[dependencyLocator[type]]]) obj[item[dependencyLocator[type]]] = true;
    Object.keys(item.dependencies).forEach(function(dep) {
      dep = sanitizeRepo(dep);
      if (!obj[dep]) obj[dep] = true;
    });
    return obj;
  }, {}));
};

var readPackages = function(root, type, allProcessed, list, overrides, callback) {
  getDir(root, type, function(error, dir) {
    if (error) return callback(error);

    var parent = sysPath.join(root, dir);
    var paths = list.map(function(item) {
      if (type === 'component') item = sanitizeRepo(item);
      return {path: sysPath.join(parent, item), overrides: overrides[item]};
    });

    each(paths, processPackage.bind(null, type), function(error, newProcessed) {
      if (error) return callback(error);
      var processed = allProcessed.concat(newProcessed);

      var processedNames = {};
      processed.forEach(function(_) {
        processedNames[_[dependencyLocator[type]]] = true;
      });

      var newDeps = gatherDeps(newProcessed, type).filter(function(item) {
        return !processedNames[item];
      });

      if (newDeps.length === 0) {
        callback(error, processed);
      } else {
        readPackages(root, type, processed, newDeps, overrides, callback);
      }
    });
  });
};


// Find an item in list.
var find = function(list, predicate) {
  for (var i = 0, length = list.length, item; i < length; i++) {
    item = list[i];
    if (predicate(item)) return item;
  }
};


// Iterate recursively over each dependency and increase level
// on each iteration.
var setSortingLevels = function(packages, type) {
  var setLevel = function(initial, pkg) {
    var level = Math.max(pkg.sortingLevel || 0, initial);
    var deps = Object.keys(pkg.dependencies);
    // console.log('setLevel', pkg.name, level);
    pkg.sortingLevel = level;
    deps.forEach(function(depName) {
      depName = sanitizeRepo(depName)
      var dep = find(packages, function(_) {
        if (type === 'component') {
          var repo = _[dependencyLocator[type]];
          if (repo === depName)
            return true;
          // nasty hack to ensure component repo ends with the specified repo
          // e.g. "repo": "https://raw.github.com/component/typeof"
          var suffix = '/' + depName;
          return repo.indexOf(suffix, repo.length - suffix.length) !== -1;
        } else {
          return _[dependencyLocator[type]] === depName;
        }
      });

      if (!dep) {
        var names = Object.keys(packages).map(function(_) {
          return packages[_].name;
        }).join(', ');
        throw new Error('Dependency "' + depName + '" is not present in the list of deps [' + names + ']. Specify correct dependency in ' + type + '.json or contact package author.');
      }
      setLevel(initial + 1, dep);
    });
  };
  packages.forEach(setLevel.bind(null, 1));
  return packages;
};

// Sort packages automatically, bas'component'ed on their dependencies.
var sortPackages = function(packages, type) {
  return setSortingLevels(packages, type).sort(function(a, b) {
    return b.sortingLevel - a.sortingLevel;
  });
};

var init = function(directory, type, callback) {
  readJson(sysPath.join(directory, jsonPaths[type]), type, callback);
};


var readComponents = function(directory, callback, type) {
  if (typeof directory === 'function') {
    callback = directory;
    directory = null;
  }
  if (directory == null) directory = '.';

  init(directory, type, function(error, json) {
    if (error) {
      if (error.code === 'NO_' + type.toUpperCase() + '_JSON') {
        return callback(null, []);
      } else {
        return callback(error);
      }
    }

    var deps = Object.keys(json.dependencies || {});
    var overrides = json.overrides || {};

    readPackages(directory, type, [], deps, overrides, function(error, data) {
      if (error) return callback(error);
      var sorted = sortPackages(data, type);
      aliases = [];
      if (type === 'component')
      {
        builder = new Builder(directory);
        var aliases = [];
        emitter.on('addAlias', function(alias) {aliases.push(alias);})
        builder.buildAliases(function(err, res) {
          callback(null, sorted, aliases);
        });
      }
      else
        callback(null, sorted);
    });
  });
};

Builder.prototype.alias = function(a,b) {
  var name = this.root
    ? this.config.name
    : this.basename;
  var res = {};
  res[name + '/' + b] = a;
  emitter.emit('addAlias', res)
  return 'require.alias("' + name + '/' + b + '", "' + a + '");';
};

var read = function(root, type, callback) {
  if (type === 'bower') {
    readComponents(root, callback, type);
  } else if (type === 'component') {
    readComponents(root, callback, type);
  } else {
    throw new Error('read-components: unknown type');
  }
};

module.exports = read;

// getBowerPaths('.', console.log.bind(console));
