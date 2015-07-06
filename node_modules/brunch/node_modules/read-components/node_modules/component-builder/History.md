
0.10.1 / 2014-01-16
==================

 * fix for lookup casing

0.10.0 / 2013-10-17
==================

 * add native json support to scripts

0.9.2 / 2013-09-12
==================

 * update require

0.9.1 / 2013-09-06
==================

 * update require

0.9.0 / 2013-07-19
==================

 * add support for building templates as strings
 * add css transpiler example
 * replace `fs-extra` with `cp`
 * change Function()-evaled code to actually include newlines
 * fix absolute path lookup problem #91

0.8.3 / 2013-06-06
==================

 * update require
 * fix url to rework in readme
 * fix leading "/" in url when urlPrefix is empty-string

0.8.2 / 2013-05-13
==================

  * fix .basename for root components not in a directory of the same config `.name`
  * fix improper asset rewrite url join on windows. Closes #94
  * fix copy/link attempts to files that ENOENT

0.8.1 / 2013-04-26
==================

  * fix root-level aliases with .main. Closes #88

0.8.0 / 2013-04-24
==================

  * add root-level aliases. Closes #83

0.7.1 / 2013-04-24
==================

  * fix edge-case directory collision when a lookup path is within a lookup path
    and has the same name as a component

0.7.0 / 2013-04-11
==================

  * add support for ./ in .main
  * add component-relative ./components lookup path. Closes #33
  * add nicer json error messages
  * fix nested .paths resolution
  * fix the need for manually adding root lookup paths
  * rename .paths -> .globalLookupPaths
  * rename .conf -> .config since it is public
  * change to sync .conf loading

0.6.5 / 2013-03-29
==================

  * fix: json to return self.conf to avoid race condition

0.6.4 / 2013-03-19
==================

  * fix: default urlPrefix to empty string. Fixes #75
  * fix hook error handling in .buildType()

0.6.3 / 2013-02-15
==================

  * add configuration to copy files instead of symlink

0.6.2 / 2013-01-04
==================

  * add .removeFile(type, filename)
  * add .alias() helper
  * rename .name to .basename
  * refactor .lookup() to use fs.existsSync

0.6.1 / 2013-01-02
==================

  * fix root-level main support for all components. Closes #53

0.6.0 / 2013-01-01
==================

  * add async hook support. Closes #43
  * update require

0.5.5 / 2012-12-30
==================

  * add lookup and readfile caching mechanisms. Closes #50
  * update require

0.5.4 / 2012-12-20
==================

  * remove rework dep

0.5.3 / 2012-12-20
==================

  * update rework

0.5.2 / 2012-12-20
==================

  * add initial plugin support
  * fix: do not rewrite urls relative to host (closes #45)
  * fix: .addFile(type) should always add files to conf[type]

0.5.1 / 2012-12-04
==================

  * fix data uri support

0.5.0 / 2012-12-04
==================

  * add source url support. Closes #39
  * fix url rewriting of css in sub-directories

0.4.2 / 2012-11-06
==================

  * Revert "add root 'main' alias for all components. Closes #26"

0.4.1 / 2012-11-06
==================

  * add root 'main' alias for all components. Closes #26

0.4.0 / 2012-11-04
==================

  * add `url()` rewriting. Closes #28
  * add asset symlinking for `.files`, `.images`, and `.fonts`

0.3.0 / 2012-10-31
==================

  * add better lookup failure message
  * fix lookup paths for use with `.local`

0.2.1 / 2012-10-24
==================

  * add better lookup failure error
  * fix incorrect root main alias. Closes #22
  * rename "bundled" to "local"

0.2.0 / 2012-10-22
==================

  * add lookup path support [Nick Jackson]

0.1.0 / 2012-10-19
==================

  * add "main" support. Closes #15
  * update component-require

0.0.7 / 2012-10-16
==================

  * update require

0.0.6 / 2012-10-12
==================

  * remove recursive --dev

0.0.5 / 2012-09-14
==================

  * add bundled support. Closes #6

0.0.4 / 2012-09-05
==================

  * renamed "devDependencies" to "development"

0.0.3 / 2012-09-05
==================

  * add `devDependencies` support. Closes #10

0.0.2 / 2012-09-01
==================

  * update component-require
