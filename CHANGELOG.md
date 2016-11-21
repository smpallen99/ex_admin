# Changelog

## 0.8.2  (2016-8-25)

### Enhancements
* Support the new side effect free xain package
* Added a number of new tests
* admin.install mix task supports brunch
  * Install assets to web/static
  * Append instructions to brunch-config.js
* admin.install --no-brunch option to install assets to priv/static
* csv macro enhancements
  * Support csv [:field1, :field2, {:field, fun/1}] format
  * Support csv column :field without the need to add a fun
  * Removed the side effect ridden builder approach
* Added I18n support with a french .do file
* Support display_name in breadcrumbs
* Support favicon
* Modified ExAdmin.Helpers.display_name to fall back back to get_name_field contents
* Updated to Phoenix 1.2
* Support Ecto 2.0
* Added experimental ajax support for dynamic for fields
  * Define a collection field, that when selected, dynamically adds a field scoped to the selected field
* Add configurable title
* Support multiple before and after controller filters
* Support override field labels on index filters box
* Added ability to replace default layout
* Allow to specify type of input explicitly
* member_action and collection_action macros now generate action links
* Consolidate js and css files into a 2-3 files per template
* Support setting explicit field types in forms
* Much more refactoring and code simplification
* Experimental support for string and integer array fields
* Scopes preserve filters
* Scope counts include filtered records
* Column sorting preserve current scope
* Russian locale
* Search options for string filters

### Bug Fixes
* Fix errors in README.md
* Remove unused factorygirl dependency
* remove batch_actions if :delete action restricted
* action_item macro now works with the new action_items macro
* csv now exports times and dates
* Fix many to many form collection without a name field
* Use get_id & display_name instead of hard-coded :id & :name columns when build select box
* Remove duplicate scope buttons
* Support multiple page files (i.e. dashbaord like pages)

### Deprecations
* actions :all macro deprecated. Use action_items instead

### Backward incompatible changes

