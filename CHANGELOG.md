Changelog for Redmine DMSF
==========================

1.4.8: *2014-04-17*
-----------------------

    Symbolic links
    Document tagging
    Localization of email notifications
    An option to send document links by email

 * New: Issue #19 - Documentation?
 * Update: Issue #106 - [Feature Request] Save files in folder structure defined via DMSF
 * Fix: Issue #107 - Problems upgrading redmine 1.3 to 2.23 regarding DMFS
 * Fix: Issue #111 - Cannot sort files in folders by date, size, etc
 * Update: Issue #139 - Error 500 on click on "details" icon
 * New: Issue #183 - Create document links
 * New: Issue #201 - Download link by email
 * Fix: Issue #205 - Ampersand shows up in displayed filenames as "&amp;" instead of "&"
 * Fix: Issue #212 - Incorrect revision information in email notification
 * Fix: Issue #214 - Required DMSF custom field prevents documents to be saved
 * Update: Issue #216 - Enhancement : having notification emails translated
 * Update: Issue #224 - Setup/Upgrade documentation
 * Fix: Issue #226 - undefined method `custom_fields_tabs' for module `CustomFieldsHelper'
 * Fix: Issue #233 - Failed Travis builds
 * Update: Issue #235 - "You are not member of the project" when changing project notification.
 * New: Issue #236 - Documents tagging
 * Fix: Issue #240 - Internal server error, redmine 2.5.1-devel.13064, PostgreSQL, dmsf 1.4.8-devel
 * Fix: Issue #242 - dsmf 1.4.8 minor ... "link form" tab
 * Fix: Issue #246 - "File storage directory" does not default properly when setting is empty   

1.4.7: *2014-01-02*
-----------------------

    Open approvals in My page
    Custom fields
    Speeding up
    Code revision

* New: Issue #38 - A few questions about the plugin (possible improvements)
* New: Issue #49 - Make the 100 MB ajax upload limit an option 
* Fix: Issue #52 - Error : undefined method `size' for nil:NilClass
* Fix: Issue #90 - Missing redmine_dmsf / assets / javascripts / plupload / i18n /en.js file?
* Fix: Issue #94 - Files not deleted with project
* Fix: Issue #95 - DMSF tab missing on closed projects
* Fix: Issue #104 - Custom fields do not work
* Fix: Issue #141 - Error 500 uploading file with DMSF custom fields
* Fix: Issue #159 - Broken links caused by plugin_asset_path implementation
* New: Issue #173 - Open approvals in My page
* Fix: Issue #174 - Workflow error when more than one approver 
* Fix: Issue #175 - Error 500 on performing search
* Fix: Issue #176 - 500 internal error when approving workflow - dmsf_workflows/4/new_action
* Fix: Issue #177 - 1.4.7-devel unable to upload files 
* Fix: Issue #178 - Error 500 cannot access Administration -> Custom Fields page
* New: Issue #179 - Workflow Log History in Detailed View
* Fix: Issue #187 - Approval workflow permissions 
* New: Issue #190 - Very slow in directories containing many files
* Fix: Issue #191 - Move/Copy gives undefined method for File:Class type: bug 
* New: Issue #193 - French translation 
* Fix: Issue #194 - Workflow name link in workflow log window 
* Fix: Issue #195 - Workflow log not displaying all the steps 
* New: Issue #196 - Update French Language
* Fix: Issue #197 - Multi upload not loading the translation
* New: Issue #198 - When editing a workflow, only show current project's users
* Fix: Issue #199 - Small error in plugin_asset_path function 
* New: Issue #200 - Update the french translation for the multi upload module
* Fix: Issue #202 - unable to create Custom Field when DMSF plugin installed
* Fix: Issue #203 - Little typing error in french translation
* Fix: Issue #206 - "Select All" checkbox not functioning
* Fix: Issue #207 - locks by deleted users producte internal server error 500

1.4.6: *2013-10-18*
-----------------------
* New: Document approval workflow
* New: Slovene language translation
* Update: German language translation
* Revisit: Issue #34 - fix does not function as expected on Rails < 3.2.6, Redmine 2.0.3 dependency added.
* Fix: Issue #75  - Wrong filename encoding in emailed zip file
* Fix: Issue #87  - RoutingError (No route matches [GET] "/javascripts/jstoolbar/lang/jstoolbar-en-IS.js"):
* Fix: Issue #103 - Multiple DMSF tabs in Administration->Custom fields & localization
* Fix: Issue #110 - 'zip' gem conflicts with 'rubyzip' on Redmine XLS Export Plugin.
* Fix: Issue #112 - Uninstall command
* Fix: Issue #116 - Translation missing for DMSF custom field tabs
* Fix: Issue #146 - Problem with Russian file names in zip
* Fix: Issue #143 - Error on missing template - has to have to_s if adding to string
* Fix: Issue #148 - I don't have a notification sent out when I upload a file
* Fix: Issue #157 - Copying files/folders from one project to another project

1.4.5: *2012-07-20*
-----------------
* New: Settings introduced to enable read-only or read-write stance to be taken with webdav
* Fix: Issue #27 - incorrect call to display column information from database (redmine 1.x fragment).
* Fix: Issue #28 - incompatible SQL in db migration script for postgresql
* Fix: Issue #23 - Incorrect call to to_s for displaying time in certain views
* Fix: Issue #24 - Incorrect times shown on revision history / documents
* Fix: Issue #25 - Character in init.rb stops execution
* Fix: Issue #34 - Incorrect scope when accessing deleted files prevented notification.

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
