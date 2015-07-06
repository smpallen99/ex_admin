progeny = require '..'
path = require 'path'
assert = require 'assert'

getFixturePath = (subPath) ->
	path.join __dirname, 'fixtures', subPath

describe 'progeny', ->
	o = potentialDeps: true

	it 'should preserve original file extensions', (done) ->
		progeny(o) getFixturePath('altExtensions.jade'), (err, dependencies) ->
			paths = (getFixturePath x for x in ['htmlPartial.html', 'htmlPartial.html.jade'])
			assert.deepEqual dependencies, paths
			do done

	it 'should resolve recursive dependencies', (done) ->
		progeny(o) getFixturePath('recursive.jade'), (err, dependencies) ->
			paths = [getFixturePath('altExtensions.jade')]
				.concat(getFixturePath x for x in ['htmlPartial.html', 'htmlPartial.html.jade'])
			assert.deepEqual dependencies, paths
			do done

	it 'should provide only real files by default', (done) ->
		progeny() getFixturePath('recursive.jade'), (err, dependencies) ->
			paths = [getFixturePath('altExtensions.jade')]
			assert.deepEqual dependencies, paths
			do done

	it 'should resolve multiline @import statements', (done) ->
		progeny(o) getFixturePath('multilineImport.scss'), (err, dependencies) ->
			# 6 non-excluded references in fixture
			# x4 for prefixed/unprefixed and both file extensions
			assert.equal dependencies.length, 24
			do done

	it 'should be truly async', (done) ->
		dependencies = null
		progeny(o) getFixturePath('altExtensions.jade'), (err, deps) ->
			dependencies = deps
			assert Array.isArray dependencies
			do done
		assert.equal dependencies, null

	it 'should return empty array when there are no deps', (done) ->
		progeny(o) 'foo.scss', '$a: 5px; .test {\n  border-radius: $a; }\n', (err, deps) ->
			assert.deepEqual deps, []
			do done

describe 'progeny.Sync', ->
	it 'should return the result', ->
		assert Array.isArray progeny.Sync() getFixturePath('altExtensions.jade')

describe 'progeny configuration', ->
	describe 'excluded file list', ->
		progenyConfig =
			rootPath: path.join __dirname, 'fixtures'
			exclusion: [
				/excludedDependencyOne/
				/excludedDependencyTwo/
			]
			extension: 'jade'
			potentialDeps: true

		it 'should accept one regex', (done) ->
			progenyConfig.exclusion = /excludedDependencyOne/
			getDependencies = progeny progenyConfig

			getDependencies getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
				paths =  (getFixturePath x for x in ['excludedDependencyTwo.jade', 'includedDependencyOne.jade'])
				assert.deepEqual dependencies, paths
				do done

		it 'should accept one string', (done) ->
			progenyConfig.exclusion = 'excludedDependencyOne'
			getDependencies = progeny progenyConfig

			getDependencies getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
				paths =  (getFixturePath x for x in ['excludedDependencyTwo.jade', 'includedDependencyOne.jade'])
				assert.deepEqual dependencies, paths
				do done

		it 'should accept a list of regexes', (done) ->
			progenyConfig.exclusion = [
				/excludedDependencyOne/
				/excludedDependencyTwo/
			]
			getDependencies = progeny progenyConfig

			getDependencies getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
				assert.deepEqual dependencies, [getFixturePath 'includedDependencyOne.jade']
				do done

		it 'should accept a list of strings', (done) ->
			progenyConfig.exclusion = [
				'excludedDependencyOne'
				'excludedDependencyTwo'
			]
			getDependencies = progeny progenyConfig

			getDependencies getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
				assert.deepEqual dependencies, [getFixturePath 'includedDependencyOne.jade']
				do done

		it 'should accept a list of both strings and regexps', (done) ->
			progenyConfig.exclusion = [
				'excludedDependencyOne'
				/excludedDependencyTwo/
			]
			getDependencies = progeny progenyConfig

			getDependencies getFixturePath('excludedDependencies.jade'), (err, dependencies) ->
				assert.deepEqual dependencies, [getFixturePath 'includedDependencyOne.jade']
				do done

	describe 'altPaths', ->
		it 'should look for deps in altPaths', (done) ->
			progenyConfig =
				altPaths: [getFixturePath 'subdir']
				potentialDeps: true
			progeny(progenyConfig) getFixturePath('altExtensions.jade'), (err, dependencies) ->
				paths = []
				paths.push getFixturePath y + x for y in ['', 'subdir/'] for x in ['htmlPartial.html', 'htmlPartial.html.jade']
				assert.deepEqual dependencies, paths
				do done

	describe 'reverseArgs', ->
		it 'should allow path, source args to be switched', (done) ->
			progenyConfig =
				potentialDeps: true
				reverseArgs: true
			progeny(progenyConfig) '@require bar\na=5px\n.test\n\tborder-radius a', 'foo.styl', (err, deps) ->
				assert.deepEqual deps, ['bar.styl']
				do done

