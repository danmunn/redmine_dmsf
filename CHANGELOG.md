Changelog for Redmine DMSF
==========================

1.4.3: *Not yet released*
-----------------------
* New: Hook into project copy functionality to permit (although not attractively)
       functionality for DMSF to be duplicated accross projects
* Update: Project patch defines linkage between DMSF files and DMSF folders.
* Update: Data linkage allowing dependent items to be deleted (project deletion for example)
          this needs to be revised as files marked deleted are not affected by this at present
* Update: README.md updated with Bundler requirement (Issue #13)
* Fix: Error in entity details page UI prevented revision management.

1.4.2: *2012-06-21*
-----------------
* New: Integration test cases for webdav functionality
* Update: Documentation has been converted from Simpletext to Markdown
* Update: Features listed in documentation
* Fix: Issue #3 - "webdav broken until set in Administrator -> Settings"
* Fix: Issue #5 - "Webdav incorrectly provides empty listing for non-DMSF enabled projects"
* Fix: Issues identified by test cases

1.4.1: *2012-06-15*
-----------------
* New: DAV4Rack requirement added (Gemfile makes reference to github repository for latest release).
* New: Webdav functionality included, additional administrative settings added
* Fixed: Issue #2 - extended xapian search fixed with Rails 3 compatible code.

1.4.0: *2012-06-06*
-----------------
* New: Redmine 2.0 or higher is required
