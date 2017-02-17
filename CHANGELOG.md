Changelog for Redmine DMSF
==========================

1.5.9 *2016-03-01*
------------------

    WebDAV 
        Documents editing in MS Office 
        Support for rsync and cp commands 
        Disable verioning for certain file names pattern by PUT request
        Ignoring certain file names pattern by PUT request
        Caching of PROPSTATS and PROPFIND requests
    REST API
        Update folders
        Finding folders by their titles
    Approval workflow
        Editing of approval workflow steps
        Approval workflow step name
    DMSF
        Document export   
        Public URLs option in email entries
        Global title format for downloading
        New columns in the main DMSF view; columns are configurable from the plugin settings

* New: #676 - An option to prevent inheritance of CF
* New: #675 - Keep documents locked after the approval workflow is finished as an option
* Bug: #671 - Webdav: MOVE returns incorrect response
* Bug: #663 - Locked documnts on My page
* Bug: #662 - Broken paging on the Add approver form
* New: #655 - ERROR: Couldn't find Project with identifier=desktop.ini
* New: #654 - Non-versioned files should not go to trash bin when deleted
* Bug: #652 - Missing date picker when creating new file
* Bug: #651 - Incomplete copy of a file to another project
* New: #648 - Lock duration
* New: #641 - Documents export
* New: #635 - Edit approval workflow steps
* Bug: #632 - database migration error (from ver 0.9.1 to ver 1.5.8)
* New: #630 - Disable versioning for certain files/file patterns
* New: #629 - Approval workflow step name
* New: #626 - Public URLs in email entries
* New: #614 - WebDAV caching
* Bug: #606 - DmsfFile.move_to does not update last_revision
* Bug: #605 - Wrong file size detection for non English language
* Bug: #603 - Send documents by email, from address is emission email address instead of user mail
* Bug: #598 - WebDAV: PROPFIND to "/" and "/dmsf" throws FATAL error
* Bug: #593 - Modern upload file type doesn't work
* Bug: #592 - reset_column_information is missing in DB migration
* Bug: #591 - rsync doesn't work for WebDAV mounted folder
* Bug: #587 - Working with MS Office documents directly in mounted WebDAV share 
* New: #584 - A lot of warnings in WebDAV unit tests
* Bug: #582 - FATAL -- : ActionController::RoutingError (No route matches [GET] "/plugin_assets/redmine_dmsf/javascripts/jquery.dataTables/zh.json")
* Bug: #581 - Webdav always shows the create date
* Bug: #580 - Revision deleting
* Bug: #579 - Wrong file size
* New: #555 - Documents ID easy access
* New: #551 - Default action for files viewing
* New: #547 - Setting Title format should be global setting, but released as local setting
* New: #499 - Add column "type/extension" in folder content view    

1.5.8 *2016-10-21*
------------------

    Drag&Drop for a new content in the new revision form
    Tree view optimization for speed
    Wiki macros revision: dmsfd X dmsfdesc
    Support for deleting users
        
* Bug: #578 - A wrong title when uploading documents type: bug
* Bug: #574 - Macro {{dmsfd(xx)}} produce blank value type: bug
* Bug: #566 - HTML tags in the document description breaks UI type: bug 
* Bug: #565 - Error 500 when a link to another folder is in the folder/project type: bug
* New: #562 - New step button text type: enhancement
* Bug: #561 - Wrong path in the document's details form type: bug
* Bug: #560 - Trying to send mail without recipient results in error 500 type: bug
* Bug: #558 - Deletion of a user type: bug
* New: #443 - Drag/drop feature for new content type: enhancement

1.5.7 *2016-08-12*
------------------
    
    SQLite compatibility
    Lock/Unlock feature for global approval workflows
    Document ID in the document's details
    New wiki macros (thumbnail, approval workflow)
    Searchable pick lists
    Tree view as an user's option
    Italian localisation

* Bug: #556 - Plugin settings "File default notifications" does not apply!
* Bug: #554 - JQeury datatable not load correct language file
* Bug: #545 - Wrong tool-tip for dmsf macro
* Bug: #544 - Approval workflow email notifications
* Bug: #542 - Link from commbo box sorting
* Bug: #538 - Migration error with Redmine 3.3
* New: #532 - Modified timestamps lost after migration
* Bug: #531 - webdav: Error -36 on OSX
* Bug: #530 - Cannot download folders with sub folders
* New: #529 - Show document description in mouseover or column
* New: #527 - Add MD5 of each revision in the detail view of documents
* Bug: #526 - The same version feature doen't work as expected
* Bug: #523 - Bug with "delegate approval step"
* Bug: #522 - File Storage Directory does not change
* New: #520 - Document link after a search ...
* New: #518 - Debian installation issues
* Bug: #506 - Document title format %t doesn't reffer to the title
* Bug: #504 - Non-fatal MySQL error when migrating documents
* New: #503 - Information about migrating documents
* Bug: #501 - If a folder or file is locked, we can't activate or deactivate notifications
* New: #500 - Automatically check the inline radiobutton when use custom version
* New: #252 - nautilus-like folders-files list view


1.5.6 *2016-01-25*
------------------

    Uploading of large files (>2GB)
    Support for *.svg and *.py in wiki macros
    File name formatting while downloading

* Bug: #498 - Webdav: Invalid handling of files with '[' or ']' in file name
* New: #497 - file.image ignore SVG type
* Bug: #494 - Unable to upload files with ruby > ruby-2.0.0-p598
* Bug: #491 - Still using original uploaded filename after filename renamed (PDF file)
* Bug: #488 - Available projects for 'link to' operation
* Bug: #487 - Not able to view the url link file, but able to Download
* Bug: #480 - Big files ( > 500mb) uploading problems
* Bug: #471 - Converting Documents to DMSF is not working
* Bug: #470 - sort function
* Bug: #469 - dmsfd doesn't reuse Wiki syntax in Wiki page
* New: #468 - Display contents of text file in Wiki page
* Bug: #465 - Install using debian 8 (jessie)
* Bug: #459 - WebDav Windows
* Bug: #458 - Cannot upload big files
* New  #44  - Append File Revision on filename when downloading file

    Maintenance release II.

1.5.5 *2015-10-19*
------------------

    Maintenance release

* Bug: #457 - Folder name Documents inaccessible
* Bug: #456 - Everything is set to DEACTIVATED but still I got notifications
* Bug: #448 - C:\fakepath\ added to Revision Filename Path
* Bug: #432 - approval process for 3 users "user1 AND user2 AND user3"
* Bug: #109 - Rename folder over webdav

1.5.4 *2015-09-17*
------------------

    New DMSF macro for inline pictures
    File name updating when a new content is uploaded
    System files filtering when working with WebDAV

 * Bug: #442 - Can't move directories
 * Bug: #441 - Drag'n'drop save only the picture thumbnail
 * New: #438 - The file name update when a new content is uploaded
 * Bug: #418 - Documents details from in IE
 * Bug: #417 - Selected column is not highlighted under mouse pointer in IE
 * New: #352 - DMSF Macro to display inline Pictures in wiki
 * New: #54  - Webdav: Filter Mac OS X "resource forks" files

1.5.3 *2015-08-10*
------------------

    Plupload 2.1.8
    Redmine >= 3.0 required

* Bug: #430 - Got 500 error when change directory name
* Bug: #427 - Can't access to WebDAV root directory
* Bug: #422 - Document uploading in IE

1.5.2 *2015-07-13*
------------------

    Redmine >= 3.0 compatibility

* Bug: #404 - Deleted folder (still in trash) results in errors while accessing parent folder via webdav
* Bug: #401 - Link between project on Redmine 3.0
* Bug: #400 - internal server error fulltext search
* Bug: #396 - Error when uploading files
* Bug: #394 - DMSF install to Redmine 3.0.3 problem
* Bug: #393 - File can't be created in storage directory (Redmine 3.0.3)
* Bug: #392 - Redmine 3 Search screen error with Xapian
* New: #391 - Searchable document details
* Bug: #387 - Wrong sorting by Modified column
* Bug: #384 - Error when trying to uninstall DMSF
* New: #383 - Missleading number of entities in documents folder
* Bug: #382 - REST API - list of document produces invalid XML
* Bug: #380 - Internal Error 500 when dmsf page is accessed
* Bug: #378 - Revision view, delete revision bug
* Bug: #377 - Can access WebDAV when redmine is located under sub-URI
* Bug: #376 - Links to deleted documents
* Bug: #374 - Number of downloads
* Bug: #373 - internal 500 error : 1.5.1 stable with redmine 3.0.1 when search in dmsf enabled project
* New: #339 - Maximum Upload Size
* Bug: #319 - webdav problem after upgrading to 1.4.9 from 1.4.6
* New: #78  - Control DMSF via REST API

1.5.1: *2015-04-01*
-------------------

    Approval workflow copying
    Polish localization
    Custom versions for new document revisions
    External links

* New: #307 - Filter mail receivers for approval workflow with file managing permission
* New: #308 - Rails 4 
* Bug: #321 - My open approvals
* Bug: #322 - Approval workflow notifications
* New: #325 - Approval workflow permission
* New: #326 - Approval workflow copying
* Bug: #327 - ArgumentError: Unknown key: :conditions. (when running migration in redmine 2.6)
* Bug: #330 - File link cannot download/email
* New: #332 - ArgumentError: Unknown key: :conditions. (when running migration in redmine 2.6)
* Bug: #323 - NoMethodError (undefined method `major_version' for nil:NilClass)
* Bug: #336 - Delete documents configuration works for all the roles
* Bug: #340 - Unwanted notifications
* Bug: #341 - Error on approval workflow
* Bug: #343 - Can't use a name of a folder already existing in the trash bin
* Bug: #350 - Link seems wrong in when clicking "Approval workflow name"
* New: #351 - [Feature Request] - overriding preconfigured Revision Tags/Steps
* Bug: #353 - Link to User in Doc-Revision seems to point to wrong target link
* New: #357 - Redmine 3.0.0 released! Compatibility with DMSF?
* Bug: #361 - incompatible encoding regexp match (UTF-8 regexp with ASCII-8BIT string)
* Bug: #366 - unable to properly uninstall under Redmine 3.0.1
* Bug: #367 - Unable to create a folder 
* Bug: #368 - Cannot create a document workflow
* Bug: #369 - Update document revision under Redmine 3.0.1
* Bug: #371 - Unable to properly uninstall the plugin
* Bug: #372 - Can't move file via WebDav

1.4.9: *2014-10-17*
-----------------------

    Trash bin
    Standard Redmine's upload form with progress bar for files > 100 MB
    WebDAV library upgrade

 * New: #130 - redmine_dmsf: last update of the folders 
 * Fix: #131 - Wiki link shows filename for all users type
 * New: #136 - `File Manipulation` permissions
 * New: #218 - Feature request: Recycle bin
 * Fix: #226 - Undefined method `custom_fields_tabs` for module `CustomFieldsHelper`
 * New: #238 - DMSF document update shows up in issue referred to in comment
 * New: #249 - Storage path for DMSF files ignores global storage path for attachments
 * New: #255 - Debian - Readme install procedure update
 * Fix: #258 - Jquery conflict with Redmine 
 * Fix: #267 - Custom fields tabs not work with last custom_fields_helper_patch.rb 
 * Fix: #269 - Workflow OR not working for second reviewer 
 * Fix: #270 - 500 Internal Server Error, redmine 2.5.1, MS SQL Server 2012, dmsf 1.4.8-master, dmsf_link.rb 
 * Fix: #275 - Typo in readme file type
 * Fix: #288 - ubuntu migrate failed 
 * Fix: #290 - error installing plugin
 * Fix: #293 - Locking of inexistent files fails
 * Fix: #298 - The same approver in one approval step
 * Update: #301 - Database normalization

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
 * Fix: Issue #226 - undefined method `custom_fields_tabs` for module `CustomFieldsHelper`
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