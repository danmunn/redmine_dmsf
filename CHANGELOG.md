Changelog for Redmine DMSF
==========================

1.4.5: *Not yet released*
-----------------------
* New: Settings introduced to enable read-only or read-write stance to be taken with webdav

1.4.4p2: *2012-07-08*
-------------------
* Fix: Issue #22 - Webdav upload with passenger/nginx fails with server error (passenger class for request.body does not contain length method.
* Fix: Additional check implemented before reading settings to prevent server error when setting is not set and default does not apply.

1.4.4p1: *2012-07-07*
-------------------
* Fix: Issue #20 - Listing not functional when using sqlite adapter
* Fix: Issue #21 - Webdav not functional under bitnami (or sub directory)
* Fix: Testcase failed to cleanup after itself
* Fix: Webdav index object identified itself as having parent under prefix'ed path (in error)
* Fix: Addition of a path_prefix routine for webdav to be able to correct redirects

1.4.4: *2012-07-01*
-----------------
* New: Locking model updated to support shared and exclusive write locks. [At present UI and Webdav only support exclusive locking however]
* New: Folders are now write lockable (shared and exclusively) [UI upgraded to support folder locking, however only exclusively]
* New: Locks can now have a time-limit [Not yet supported from UI]
* New: Inereted lock support (locked folders child entries are now flagged as locked)
* Fix: Some testcases erroniously passed when files are locked, when they should be unlocked
* Update: Webdav locks files for 1 hour at a time (requested time is ignored)
* New: Files are now stored in project relevent folder
* New: Implementation of lockdiscovery and supportedlock property requests
* New: Locks store a timestamp based UUID string enabling better interaction with webservices
* Fix: Issue #16 - unable to add new project when plugin enabled due to bug in UI
* Fix: Issue #17 - dav4rack not installable on some systems - it is now vendored
* Fix: Issue #18 - Warnings thrown due to space between function and parentheses 

1.4.3: *2012-06-26*
-----------------
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
