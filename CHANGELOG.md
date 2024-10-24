Changelog for Redmine DMSF
==========================

3.2.4 *2024-10-24*
------------------

    Multiple file upload fix

* Bug: #1559 - Multiple files upload
* Bug: #1558 - Deleting of uploaded files

3.2.3 *2024-10-18*
------------------
 
    Uploaded file size fix

* Bug: 1556 - Wrong file size when uploading documents

3.2.2 *2024-10-09*
------------------

    Upload and Commit in one step
    Documents' details in issue form

* Bug: #1553 - Wiki Tool always in English after installing DMSF Plugin
* New: #1552 - Adds further text to reset button of webdav digest
* Bug: #1551 - Changes token action name for WebDAV digest
* Bug: #1550 - Some controller hooks won't get loaded
* New: #1548 - Document's details in issue form
* Bug: #1544 - Delete uploaded file and upload a different file

3.2.1 *2024-09-02*
------------------

    DMSF digest fix
    Redmine finance plugin compatibility

* Bug: #1541 - Missing Digest
* Bug: #1540 - Activity stream is not showing the document name
* Bug: #1424 - Internal error while opening Settings page

3.2.0 *2024-04-23*
------------------

   Redmine Product plugin compatibility

* Bug: #1537 - SystemStackError when Redmine Products plugin installed

3.1.9 *2024-07-18*
------------------

    Maintenance release

* Bug: #1534 - Formating is not applied to Comment column


3.1.8 *2024-07-04*
------------------

    German translation update
    Several bugs fixed

* Bug: #1533 - Mysql2::Error::TimeoutError
* Bug: #1532 - Target folder and project are the same as current 
* Bug: #1531 - Fixing NoMethodError in DmsfFileRevisionFormat
* New: #1529 - Maintenance/update german translation

3.1.7 *2024-06-28*
------------------

    Maintenance release

* Bug: #1528 - WebDAV / LDAP-User errors 

3.1.6 *2024-06-04*
------------------

* Bug: #1526 - Missing template, responding with 404: Missing partial twofa_backup_codes/_sidebar, application/_sidebar

3.1.5 *2024-06-04*
------------------

    WebDAV digest authentication
    Inline displaying of text files

* Bug: #1522 - [ ] in webdav paths seem to make issues with ms-office products
* Bug: #1518 - Mailer partial causes deprecation warning: Rendering actions with '.' in the name is deprecated
* Bug: #1517 - The file is not uploaded to the custom file field
* New: #1502 - Office files preview OK, but text and markdown file downloaded directly
* New: #1464 - Basic authentication sign-in prompts are blocked by default in Microsoft 365 Apps

3.1.4 *2024-05-06*
------------------

    Extended issue email notifications

* New: #1515 - Adds missing safe_attribute for dmsf_not_inheritable
* New: #1511 - Adds further validations
* Bug: #1510 - Uncaught SyntaxError: Redeclaration of let modal in Approval Workflow Log
* Bog: #1506 - Adminstration-settings cannot open after dmsf installed
* Bug: #1505 - Adds an extra check in DmsfQuery#dmsf_node
* New: #1503 - Issue notifications
* Bug: #1501 - Problem clicking action menu (three dots) in DMS file grid
* Bug: #1500 - Non-admin user: NoMethodError for intersect if running on Ruby 2.7.6
* Bug: #1499 - Allow access only to xxx group , access Internal error 500
* Bug: #1495 - DMSF doesn't ignore filepattern when LOCK and UNLOCK requests
* Bug: #1494 - Not sending documents when sender is set to user
* Bug: #1493 - Missing translation :notice_account_unknown_email
* Bug: #1491 - Empty system folders

3.1.3 *2023-11-15*
------------------

    DMS Document revision as a new custom field type
    Copy/Move of multiple entries
    REST API
        Entries operation (copy, move, download, delete)
    Compatibility with Redmine 5.1

IMPORTANT: REST API for copying/moving has changed. Check *extra/api/api_client.sh*.

* Bug: #1490 - Latest plugin version on windows: problematic dependency 'xapian-ruby'
* Bug: #1486 - Some context menu improvements 
* Bug: #1485 - Renames locales/ua.yml
* Bug: #1484 - Author should be kept when moving a folder type
* Bug: #1483 - Setting.plugin_redmine_dmsf['dmsf_index_database']: undefined method 'strip' for nil:NilClass
* Bug: #1479 - Cannot uninstall plugin
* Bug: #1477 - Watch permission won't work
* New: #1474 - Removes main menu from workflows controller
* Bug: #1473 - Edited documents cannot be unlocked
* Bug: #1472 - Failed upgrade up to version 3.1.1 from version 3.0.12
* New: #1248 - Make DMS document available as Type of a custom field
* New: #1132 - Please provide a simple file operation menu 

3.1.2 *2023-08-23*
------------------

    Bug fixing

* Bug #1469 - Can't access a folder under watch, but works again when unwatching the folder

3.1.1 *2023-08-17*
------------------

    Bug fixing

* Bug #1466 - Wrong number of arguments in dmsf links new 

3.1.0 *2023-08-10*
------------------

    Compatibility with Redmine 5.1
    Ukrainian translation

* New: #1461 - I want to add a Ukrainian translation to this wonderful plugin
* Bug: #1459 - Fix .zero? error in id_attribute check
* New: #1458 - V3.0.13 update error: Error in bundle plugins vault&dashboard

3.0.13 *2023-06-21*
------------------

    Italian and German localization updated
    OCR supported in full-text search
    Source codes of the plugin are checked with Rubocop

* Bug: #1457 - Wiki Macros present a 'http' link regardless of whether redmine is configured for http or https
* New: #1455 - (Partially) updated IT translation
* Bug: #1454 - After file convert view permissions missing
* Bug: #1453 - I downloaded files from devel branch and put them into plugin folder. Then I run
* Bug: #1452 - API call "commit" not accepting "custom_version_major", "custom_version_minor" anymore?
* Bug: #1449 - Lost attachment on bulk edit
* Bug: #1448 - Convert documents fails
* New: #1445 - To support OCR feature
* Bug: #1444 - Feature/add notification labels  
* New: #1443 - Updates german translations
* Bug: #1439 - Error when opening Setting page
* Bug: #1438 - Error while de-installing the plugin "Validation failed: Name contains invalid character(s)"
* Bug: #1434 - File view permissions issue

3.0.12 *2023-03-15*
------------------

    Bug fixing

* Bug: #1436 - Cannot upload new content

3.0.11 *2023-03-14*
------------------

    Bug fixing

3.0.10 *2023-03-10*
-------------------

    Maintenance release

* Bug: #1433 - User's guide broken link
* Bug: #1426 - Adds formatting helper to all editors

3.0.9 *2023-02-10*
------------------

    Sorting
    Filtering by custom fields
    Download notifications
    Embedded help
    DMS macros in wiki toolbar

* Bug: #1425 - Default sorting is not set
* Bug: #1424 - Internal error while opening Settings page
* Bug: #1423 - Check for Illegal characters in file name
* New: #1421 - Help
* Bug: #1419 - Missing checksum
* Bug: #1417 - Query::StatementInvalid raised in dmsf#show when filtering custom fields with PostgreSQL database
* New: #1414 - An empty minor version
* Bug: #1413 - Vim edit through webdav causes lose of all file versions besides last.
* Bug: #1408 - Lost attachment 2
* New: #513  - Email Notification when someone downloads a file
* New: #239  - Easy Document link macro creation 

3.0.7 *2022-11-01*
------------------

    AlphaNode's plugins compatibility
    Approval workflow enhancement
    Global search
    New filters

* Bug: #1407 - Error on "New step or New Approver"
* New: #1247 - Global DMS view - Search by title does not work
* New: #1192 - Suggest to show Approval option in list view instead hiding it in second layer menu being folded
* New: #1124 - New UI: Add additional filter "Locked documents"
* New: #1118 - How can I add 'Comment' column in the file list view?
* Bug: #880  - Removing steps of approval_workflows causes data corruption

3.0.6 *2022-09-20*
------------------

    Default query
    GitHub CI
    PosgrSQL compatibility

* Bug: #1401 - Duplicated steps in "New step" form
* Bug: #1399 - Open 'watched' folder throw internal error
* Bug: #1397 - System folder is not deleted
* New: #1396 - Repeatable rake task to sync documents
* Bug: #1395 - Use custom fields in filter throw error 500
* New: #1386 - Changing default file query

3.0.5 *2022-08-20*
------------------

    Aproval wokflows notifications fix

* Bug: #1394 - Email notifications for workflows are not sent

3.0.4 *2022-08-19*
-------------------

    Version macro extension

* Bug: #1392 - Issue #1388 patch
* Bug: #1391 - Fix plugin name redmine_checklists
* New: #1390 - Version of revision in wiki
* Bug: #1388 - Custom field in DMS Columns
* Bug: #1387 - Error in bundle with plugin custom table
* Bug: #1385 - Wrong version when uploading a document via WebDAV
* Bug: #1384 - Checksum is always the same via WebDAV

3.0.3 *2022-07-19*
-------------------

    Security enhancement
    Persian localisation
    DMSF images in PDF export

* Bug: #1382 - Unable to copy or move files
* Bug: #1381 - Update fa.yml
* Bug: #1380 - Custom queries and Trash bin
* New: #1377 - Create fa.yml
* New: #1375 - Hide the link in the TOP menu
* Bug: #1374 - Possible XSS Vulnerability by using eval()
* Bug: #1373 - Cross-site Scripting risk in Select2 < 4.0.8
* Bug: #1372 - Replacing view_dmsf_file_path references with view_dmsf_file_url
* Bug: #1371 - Mail rendering of DMSF file link reports undefined method error
* Bug: #1369 - Translate settings column names
* Bug: #1368 - Wrong translation in Persian and probably some other languages
* New: #1082 - More than one ID in image rendering macros
* Bug:  #903 - Little bug in PDF image export (Redmine 3.4.6)

3.0.2 *2022-06-17*
-------------------

    MS SQL compatibility
    RedmineUp's plugins compatibility

* Bug: #1366 - 404 Not found while restoring documents from the trash bin
* Bug: #1365 - No journal when delete / de-attach document
* Bug: #1364 - Error while loading /settings
* Bug: #1363 - Conflict with plugin redmine_issue_evm
* Bug: #1352 - Error while loading list DMSF

3.0.1 *2022-06-03*
-------------------

    Inline displaying of office documents
    Custom fields displayed by folders
    Compatibility with RedmineUp's plugins
    Compatibility with Issue EVM plugin
    New hooks

* Bug: #1363 - Conflict with plugin redmine_issue_evm
* New: #1361 - Progress bar modal when handling document upload
* New: #1360 - Use Redmine's temp folder
* New: #1359 - Add download icon
* New: #1358 - Remove the magnifier icon
* Bug: #1357 - Check convert available by thumbnails
* Bug: #1356 - Remove a drive letter when using WebDAV in Windows
* New: #1355 - Hook Request
* Bug: #1354 - Redmine Configuration Page not working when DMSF is installed together with RedmineUp resources plugin
* New: #1353 - Cannot preview my doc
* Bug: #1350 - Internal Error while opening settings
* Bug: #1349 - QueryColumn - Error
* New: #1348 - Custom Fields not shown on folder level
* Bug: #1345 - Conflict with RedmineUP invoice plugin
* New: #1227 - Check if a document contains a signature
* New: #1203 - Suggest to add document preview 

3.0.0 *2022-04-28*
-------------------

    Redmine 5.0
    Watchable documents and folders (The original DMS notifications ar off as default. They can be activated in Administration->Settings->Email notifications.)
    Patch version

* New: #1344 - Need support Redmine 5
* Bug: #1343 - New content input field improvement
* Bug: #1340 - Using plugin with Redmine SVN trunk
* Bug: #1339 - Not show action menu to unlock folder
* Bug: #1338 - move/copy folder from project1 to project2
* New: #1337 - Project's plus menu extension
* New: #1336 - New file menu item
* New: #1333 - Memory problem in 'My page' with 'Open aprovals' option
* Bug: #1330 - Trouble with dmsff macro
* Bug: #1329 - Problem moving a folder with locked files.
* New: #1328 - Update de.yml
* New: #1323 - Fast links for Copy/Move
* Bug: #1318 - easy_gantt compatibility
* Bug: #1317 - Wrong links to a project
* Bug: #1314 - Fix HTTP Status 500 when emailing document link
* Bug: #1313 - Impossible to use macro in the revision comment field.
* New: #1312 - Update _log.html.erb
* Bug: #1311 - Deleting the link between files and issues
* New: #1151 - Add document revision.patch_version
* New:  #557 - Watch Documents

2.4.11 *2021-11-03*
-------------------

    GitLab CI
    REST API
        Copy and move of documents and folders
    PostreSQL fixed

* New: #1309 - Gitlab CI
* Bug: #1306 - Mysql2::Error: Operand should contain 1 column(s)
* Bug: #1304 - SQL error with postgresql on top menu
* New: #1301 - REST API for documents movement 

2.4.10 *2021-10-20*
-------------------

    German and English localisation improvement

* Bug: #1299 - Added missing phrases in German translation, corrected typos (DE, EN)

2.4.9 *2021-11-15*
------------------

    Project copying DMSF options fixed.
    Dalli dependency removed.

* Bug: #1297 - Redmine KO after dalli upgrade to 3.0
* Bug: #1296 - "Copy folders only" doesn't work properly

2.4.8 *2021-10-08*
------------------

    REST API 
        Create a revision, updating custom fields
    Bug fixes

* Bug: #1290 - Column is not shown. GUI is not changed
* Bug: #1284 - 500 Error when doing Approval Workflow related actions #1260
* Bug: #1283 - Rest API: link file to an issue
* Bug: #1282 - Current view changed after adding new revision
* Bug: #1280 - Problem with editing an exisiting link
* Bug: #1279 - Error when sorting on custom field
* Bug: #1277 - Custom field not set as default column
* Bug: #1272 - Document tagging/filtering: filter not working when tag has multiple values
* Bug: #1267 - Document editing from a mounted folder in MS Excel 2016
* Bug: #1265 - Cannot unlock a folder despite :force_file_unlock permission
* Bug: #1262 - Redmine version dependency differs between readme.md and init.rb
* Bug: #1260 - 500 Error when doing Approval Workflow related actions
* Bug: #1258 - Unlock folder results in 403
* Bug: #1255 - Sub Folder creation via REST API
* Bug: #1254 - SQL Error when trying to list certain folders
* Bug: #1252 - WebDAV error
* New: #1245 - Update custom fields of a file with REST API

2.4.7 *2021-05-12*
------------------

    Bug fixes

* Bug: #1251 - DMSF Security Vulnerability
* Bug: #1249 - Bug Version field interpreting int as BigDecimal

2.4.6 *2021-04-30*
------------------

    Global DMS view
    Sub-projects as sub-folders
    Redmine 4.2

* Bug: #1243 - Fixes modification during iteration
* New: #1241 - Get File by API with Custom Fields
* Bug: #1238 - Ubuntu 20.04 dependencies install problem
* New: #1232 - Allow approval workflow actions only on x.0 file versions
* Bug: #1231 - API doesn't respond like described in the docs
* New: #1230 - Redmine 4.2.0 support
* Bug: #1229 - Error when sorting by a custom field
* Bug: #1221 - WebDAV links to non top-level directories are broken
* New: #1217 - Global DMS view
* Bug: #1215 - DMS Documents > New file does not respect theme styles properly
* Bug: #1214 - Error 500 when create new revision
* Bug: #1213 - DMS project preferences do not save
* New: #1211 - Highlight admin menu item and very little fix of ProjectPatch#copy
* New: #1209 - Added some translations // Fixed typo
* New: #1207 - Sub-projects as sub-folders
* New: #1206 - Support for .xlsm files in Edit content
* New: #1204 - Empty trash bin function is missing
* New: #1201 - Givable roles for folder's permissions
* New: #1200 - Improvement of german translations
* New: #1199 - Breakdown structure of folders if a filter is set
* Bug: #1198 - 500 Internal error when press the DMS Modules
* New: #1196 - Add workflow step name to mail notification
* New: #1195 - Move to the bottom button
* Bug: #1194 - Cannot delete a link if the linked object is locked

2.4.5 *2020-11-10*
------------------

    Sub-projects as sub-folders in WebDAV
    Delete and restore functions for non-empty folders
    A new wiki macro for embedded videos

* Bug: #1184 - Problems uploading files with the same file name as attachments on Redmine issues
* Bug: #1183 - Update README.md
* Bug: #1179 - Can not make file or folder which have the same name as the project's root folder, and etc.
* New: #1178 - Failed to PUT files which includes some characters via WebDAV
* Bug: #1175 - Available in CSV Internal Error
* Bug: #1172 - Manually locking document disables "Edit content"
* Bug: #1170 - Max size of upload-able file
* Bug: #1166 - Version column in documents table can't display letters
* Bug: #1165 - DMSF 2.4.4 1 byte files issue
* New: #1164 - Embed video into wiki
* Bug: #1163 - Folder visible via webdav but not via UI
* Bug: #1159 - Approval workflow log not available for non-admin users
* Bug: #1156 - Editing a document also changes its title
* Bug: #1155 - Bug easy context menu
* Bug: #1150 - Uploading big files causes no memory exception
* New: #1145 - Folder can not be deleted if the folder contains files or folders
* New: #1136 - WebDAV tree structure including sub-projects duplicate
* New: #1023 - New UI: List view improvements
* New: #1122 - New UI: Custom fields as filters
* Bug: #1088 - Webdav link contains SUB-URI part twice
* New: #460 - Webdav: Parent-sub Project Folders Seperated

2.4.4 *2020-07-10*
------------------

    Maintenance release

* New: #1144 - Who has locked the document information is missing.
* Bug: #1142 - How to configure "Direct document or document link sending via email"?

2.4.3 *2020-06-12*
------------------

    Redmine's look&feel 
    Implementation of folders movement between projects (WebDAV)
    Korean localization updated
    

* New: #1129 - New UI: Optimize Actions Menu
* New: #1128 - New German translations
* New: #1127 - Help integrating new feature - Auto-update word files with dmsf revision
* Bug: #1125 - New UI: Question concerning the new filtering options
* Bug: #1121 - New UI: Saving Query -> Internal Server Error
* Bug: #1120 - New UI: Values of custom fields not visible
* New: #1119 - Button "New folder" maybe must be replaced nearly button "New file" (UI better solution)
* New: #1115 - Ruby 2.3 compatibility
* New: #1112 - Update ru.yml
* Bug: #1110 - Error redmine 4.1.1 after devel-2.4.3 dmsf upgrade
* Bug: #1106 - Status 404 after moving the folder to another project
* New: #1100 - Update Korean translation
* Bug: #1095 - Public URL date cannot be set in Chromium based browsers
* New: #1084 - Update Korean translation
* New: #1080 - Redmine look and feel
* Bug: #1075 - DMSF main page not opening for a few users (Error 500)
* New: #236  - Documents tagging
* New: #29   - Improve/AJAXify DMSF browsing UI

2.4.2 *2020-01-21*
------------------

    Compatibility with Redmine 4.1
    Chinese localisation updated
        
* New: #1072 - Bug deprecation multiple gemfile sources
* New: #1069 - Minor version is limited to 99 max - I recommend to change the limit to 999
* New: #1068 - [travis] test redmine 4.1.0
* New: #1067 - update redmine extensions
* New: #1066 - Create zh-TW.json
* Bug: #1065 - Installation error version 2.4.1
* Bug: #1064 - Wrong sorting of Czech characters
* Bug: #1060 - XSS fix
* Bug: #1058 - DMS form flickering on page reload
* New: #1055 - Autofill of folder link name
* New: #1054 - Displaying of inherited permission in Folder permissions
* Bug: #1052 - Accessible even if WebDAV is disabled
* Bug: #1051 - redmine:dmsf_alert_approvals rake task on closed projects
* Bug: #1046 - Redirect to parent folder after folder edit
* Bug: #1041 - Download button gets disabled after first download
* Bug: #1038 - Webdav not open file
* Bug: #932  - Undefined method 'to_prepare' for ActionDispatch::Reloader:Class (Redmine 4.0 / Rails 5)
* Bug: #913  - ActionController::RoutingError (No route matches [PROPFIND] "/")
* New: #908  - Wrapping problem in Issue view

2.4.1 *2019-09-13*
------------------

    Compatibility with Redmine 4.0.4
    Japanese localization updated
    Plupload & DataTables libraries upgraded
     
* Bug: #1033 - Bitnami Redmine 4.0.4
* New: #1032 - Deprecate silverlight support?
* New: #1023 - Project menu is not displayed in Redmine 4.0.3 
* Bug: #1019 - Internal Erro 500 when enable "Act as attachable" and access Activity page
* Bug: #1017 - Multiple zip files are filling the tmp folder
* Bug: #1015 - WebDAV client error
* Bug: #1013 - Approval workflow notifications are sent to locked users
* Bug: #1010 - Installing Redmine in a sub URI
* Bug: #1008 - Description field trunkates on blank line
* Bug: #1004 - Wrong revision order after upgrading to DMSF 1.6.2 
* Bug: #1003 - Wrong file structure on migrate
* Bug: #1002 - New folder with empty titlle => Error 500
* Bug: #1001 - User Permission problem (can't choose user)
* Bug: #995  - All files and folders deleted during migration
* Bug: #992  - No such file to load -- mime/types.rb (LoadError)
* Bug: #988  - Failure to Update DMSF from 1.5.9 to 2.0.0 during migrate
* New: #987  - Update Japanese translation
* Bug: #986  - I can not send file by mail
* Bug: #984  - Uninitialized constant Redmine::IntegrationTest NameError
* Bug: #980  - Copy of root folder to subfolder causes web crash
* Bug: #932  - Undefined method `to_prepare' for ActionDispatch::Reloader:Class (Redmine 4.0 / Rails 5)
* Bug: #918 - Some local json file doesn't load
* Bug: #905 - Custom Fields of type 'url' are displayed "as plain text" in document listing.

2.0.0 *2019-02-28*
------------------

    Compatibility with Redmine 4.0
    Russian localization updated
    
* Bug: #976 - Can't link document to issue with column in subject
* Bug: #969 - About the DMSF folder search logic
* Bug: #966 - folder_manipulation permission
* Bug: #965 - tag column missing in the dms_file_revision_table
* Bug: #959 - crete symbolic link error
* Bug: #956 - About "External" of "Link from"
* Bug: #950 - Wrong description, missing argument for macro {{dmsft}}
* Bug: #940 - dav4rack license
* Bug: #937 - Documents upload if disk is full
* Bug: #936 - Then go to configuration an internal error #500 appear
* Bug: #935 - Upload failure for 2.0
* Bug: #934 - problem to get reversion error
* Bug: #933 - změny v xapian_indexer
* Bug: #932 - undefined method `to_prepare' for ActionDispatch::Reloader:Class (Redmine 4.0 / Rails 5)
* Bug: #929 - Problems in revision history
* New: #928 - About Redmine 4.0.0
* New: #576 - Installation problem 1.5.7 (step 4 of the guide)

1.6.2 *2018-12-04*
------------------

    REST API
        doc/folder deletion
        doc's title property added
        creating links
        limit & offset parameters added for pagination
    Speed up
        Fast links option
        Folder edit's form
    Approval workflow
        Obsolete state added

* Bug: #907 - label_webdav is duplicated in local files
* New: #887 - REST API 'Get document' : 'title' property is missing in response
* Bug: #885 - Open Remote in LibreOffice
* Bug: #881 - DMSF access for anonymous users
* New: #878 - Enlarge "Link To" form fields
* Bug: #867 - Attached documents remain by issues after they had been deleted in the main Document view
* Bug: #866 - A problem by attaching documents to issues
* New: #857 - Xapian not indexing repository if project configuration is blank
* New: #855 - Workflow notification missing
* New: #852 - Create symbolic link using REST API
* New: #850 - REST API and pagination on collection resources
* New: #847 - REST API and delete Folder/document
* New: #823 - Office URI Scheme for direct editing of MS Office files
* Bug: #818 - Xapian not available
* New: #803 - 'Create folder' takes a very long time
* New: #798 - Possibility of Obsolete an Approved Version of a Document

1.6.1 *2018-04-03*
------------------
        
    Javascript on pages is loaded asynchronously
    Obsolete Dav4Rack gem replaced with an up to date fork by Planio (Consequently WebDAV caching has been removed, sorry...)        
        Cloned from gem https://github.com/planio-gmbh/dav4rack.git    
    Project members can be chosen as recipients when sending documents by email
    Responsive view (optimized for mobile devices)
    Direct editing of document in MS Office
    Korean & Dutch localisation
    Move folder feature
    Document versions can contain letters
    
IMPORTANT

1. `alias_method_chain` has been replaced with `prepend`. Not directly but using `RedmineExtensions::PatchManager`.
   Consequently, there might occure conficts with plugins which overwrite the same methods.    
    
* Bug: #839 - Webdav not working
* New: #838 - Rake task for regenerating document's digests
* Bug: #831 - ActionView::Template::Error, when i am creating issue from the list of all projects
* Bug: #830 - ActiveRecord::StatementInvalid: Mysql2::Error: Table 'dmsf_file_revisions' doesn't exist
* Bug: #827 - Can't see files via WebDav, but see them via web-portal
* New: #823 - Office URI Scheme for direct editing of MS Office files
* New: #821 - Security Issue (Mail-Spoofing)
* Bug: #817 - The check for approval is not displayed
* Bug: #812 - Moving Issue to other project does not move attached documents in DMS
* Bug: #807 - alias_method_chain is deprecated
* Bug: #805 - Missing access check in search results
* New: #804 - Move folder
* New: #803 - 'Create folder' takes a very long time
* New: #802 - def log_activity functions
* New: #801 - Editing user in an approval workflow step
* New: #793 - Support for letters as the major version
* New: #790 - Confusing search options titles
* Bug: #789 - Mail Notification for deletion missing
* Bug: #784 - Document digist is not calculated when uploading via WebDAV
* New: #783 - Redmine uses SHA256 instead of MD5 for file digests
* New: #736 - Setting tmp folder path via ENV
* New: #726 - Keep the modification date of the file
* Bug: #716 - Microsoft Office webdav save throwing some UTF8 filename problems
* Bug: #708 - Configuration of the email sending form
* Bug: #687 - Not sorting correctly by the column title
* New: #682 - Responsive view
* New: #637 - Case of blank filetitle with revision id
* New: #628 - To rename members.title_format to members.dmsf_title_format
* Bug: #616 - An attempt to create a folder in the root causes an infinite loop
* New: #492 - Does the redmine_dmsf support to choose the members of current project when email?
* New: #231 - Better referencing macro

1.6.0 *2017-09-12*
------------------

    Folder permissions    
    Documents attachable to issues
    Hungarian localization
    Full-text search in *.eml and *.msg

IMPORTANT

1. Files in the filesystem are re-organized by a new system based on dates. So, documents are not stored in folders named 
    by the project's identifier but by the data of uploading, e.g. 2017/09. It's the same system used by Redmine for 
    attachments.
2. DMS storage directory plugin option is related to the rails root directory.
3. The plugin is independent of the gem xapian-full-alaveteli which has been replaced with ruby-xapian package. Therefore
    is recommended to uninstall xapian-full-alaveteli gem and install ruby-xapian package in order the full-text search
    is working. 
    
* Bug: #758 - Error in template when retrieving details of a file in a subfolder
* New: #755 - Ability to retrieve the MD5 value of a Document type 
* Bug: #749 - REST API - List of documents in folder fails when using folder_title
* Bug: #747 - Background icon repeating in admin panel (Redmine 3.4.2)
* Bug: #746 - Thumbnail macro: size paramter not respected
* Bug: #744 - Full stops within filename lead to false extensions
* New: #742 - WebDAV PROPSTATS and PROPFIND caching change
* Bug: #738 - Upload failure
* Bug: #734 - DMSF uploader seems to override built in uploader
* New: #733 - Make the storage path Rails.root related
* Bug: #732 - Buggy tree view
* Bug: #731 - Add users for new step in Worflow Dialogue
* Bug: #730 - Workflow "New Step" dialog not appearing
* Bug: #728 - Internal error 500 when uploading document via Edit issue
* New: #727 - Ability to disable document upload in issues
* Bug: #725 - Can't uninstall redmine dmsf in Bitnami
* New: #717 - Enhacement: Xapian parse eml and msg files in same way as word, excel...
* Bug: #714 - The full text search does not work
* New: #713 - Hungarian localisation
* New: #712 - Notifications ON/OFF are confusing
* Bug: #710 - Can't delete locked documents from the trash
* Bug: #701 - How tagging with multiple values works?
* Bug: #700 - 'Save as' from Excel does not work when using project names
* New: #699 - Speed up the main view
* New: #697 - Email notifications from WebDAV interface
* Bug: #694 - redmine:dmsf_convert_documents
* Bug: #693 - redmine:dmsf_convert_documents
* Bug: #692 - Error migrate plugin v1.5.9
* New: #691 - The last approver in the CSV export
* Bug: #685 - Problem deleting plugin
* Bug: #683 - Approval reminder problem
* New: #667 - A better navigation in found results
* New: #651 - Incomplete copy of a file to another project
* Bug: #623 - Option "Navigate folders in a tree" seems not to be saved 
* New: #543 - Feature Request: Document Location - Folder Structure
* New: #170 - Document and Folder Access Control. This issue may be duplicated as I saw it on google code some time ago.
* New: #48  - Linking Issues and DMSF Documents

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
        
* Bug: #578 - A wrong title when uploading documents
* Bug: #574 - Macro {{dmsfd(xx)}} produce blank value
* Bug: #566 - HTML tags in the document description breaks UI 
* Bug: #565 - Error 500 when a link to another folder is in the folder/project
* New: #562 - New step button text
* Bug: #561 - Wrong path in the document's details form
* Bug: #560 - Trying to send mail without recipient results in error 500
* Bug: #558 - Deletion of a user
* New: #443 - Drag/drop feature for new content

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
* New: #44  - Append File Revision on filename when downloading file

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
-------------------

    Trash bin
    Standard Redmine's upload form with progress bar for files > 100 MB
    WebDAV library upgrade

* New: #130 - redmine_dmsf: last update of the folders 
* Bug: #131 - Wiki link shows filename for all users type
* New: #136 - `File Manipulation` permissions
* New: #218 - Feature request: Recycle bin
* Bug: #226 - Undefined method `custom_fields_tabs` for module `CustomFieldsHelper`
* New: #238 - DMSF document update shows up in issue referred to in comment
* New: #249 - Storage path for DMSF files ignores global storage path for attachments
* New: #255 - Debian - Readme install procedure update
* Bug: #258 - Jquery conflict with Redmine 
* Bug: #267 - Custom fields tabs not work with last custom_fields_helper_patch.rb 
* Bug: #269 - Workflow OR not working for second reviewer 
* Bug: #270 - 500 Internal Server Error, redmine 2.5.1, MS SQL Server 2012, dmsf 1.4.8-master, dmsf_link.rb 
* Bug: #275 - Typo in readme file type
* Bug: #288 - ubuntu migrate failed 
* Bug: #290 - error installing plugin
* Bug: #293 - Locking of inexistent files fails
* Bug: #298 - The same approver in one approval step
* Update: #301 - Database normalization

1.4.8: *2014-04-17*
-------------------

    Symbolic links
    Document tagging
    Localization of email notifications
    An option to send document links by email

* New: #19 - Documentation?
* New: #106 - [Feature Request] Save files in folder structure defined via DMSF
* Bug: #107 - Problems upgrading redmine 1.3 to 2.23 regarding DMFS
* Bug: #111 - Cannot sort files in folders by date, size, etc
* Bug: #139 - Error 500 on click on "details" icon
* New: #183 - Create document links
* New: #201 - Download link by email
* Bug: #205 - Ampersand shows up in displayed filenames as "&amp;" instead of "&"
* Bug: #212 - Incorrect revision information in email notification
* Bug: #214 - Required DMSF custom field prevents documents to be saved
* New: #216 - Enhancement : having notification emails translated
* New: #224 - Setup/Upgrade documentation
* Bug: #226 - undefined method `custom_fields_tabs` for module `CustomFieldsHelper`
* Bug: #233 - Failed Travis builds
* New: #235 - "You are not member of the project" when changing project notification.
* New: #236 - Documents tagging
* Bug: #240 - Internal server error, redmine 2.5.1-devel.13064, PostgreSQL, dmsf 1.4.8-devel
* Bug: #242 - dsmf 1.4.8 minor ... "link form" tab
* Bug: #246 - "File storage directory" does not default properly when setting is empty   

1.4.7: *2014-01-02*
-------------------

    Open approvals in My page
    Custom fields
    Speeding up
    Code revision

* New: #38  - A few questions about the plugin (possible improvements)
* New: #49  - Make the 100 MB ajax upload limit an option 
* Bug: #52  - Error : undefined method `size' for nil:NilClass
* Bug: #90  - Missing redmine_dmsf / assets / javascripts / plupload / i18n /en.js file?
* Bug: #94  - Files not deleted with project
* Bug: #95  - DMSF tab missing on closed projects
* Bug: #104 - Custom fields do not work
* Bug: #141 - Error 500 uploading file with DMSF custom fields
* Bug: #159 - Broken links caused by plugin_asset_path implementation
* New: #173 - Open approvals in My page
* Bug: #174 - Workflow error when more than one approver 
* Bug: #175 - Error 500 on performing search
* Bug: #176 - 500 internal error when approving workflow - dmsf_workflows/4/new_action
* Bug: #177 - 1.4.7-devel unable to upload files 
* Bug: #178 - Error 500 cannot access Administration -> Custom Fields page
* New: #179 - Workflow Log History in Detailed View
* Bug: #187 - Approval workflow permissions 
* New: #190 - Very slow in directories containing many files
* Bug: #191 - Move/Copy gives undefined method for File:Class 
* New: #193 - French translation 
* Bug: #194 - Workflow name link in workflow log window 
* Bug: #195 - Workflow log not displaying all the steps 
* New: #196 - Update French Language
* Bug: #197 - Multi upload not loading the translation
* New: #198 - When editing a workflow, only show current project's users
* Bug: #199 - Small error in plugin_asset_path function 
* New: #200 - Update the french translation for the multi upload module
* Bug: #202 - unable to create Custom Field when DMSF plugin installed
* Bug: #203 - Little typing error in french translation
* Bug: #206 - "Select All" checkbox not functioning
* Bug: #207 - locks by deleted users producte internal server error 500

1.4.6: *2013-10-18*
-------------------

* New: Document approval workflow
* New: Slovene language translation
* New: German language translation
* Bug: #34 - fix does not function as expected on Rails < 3.2.6, Redmine 2.0.3 dependency added.
* Bug: #75  - Wrong filename encoding in emailed zip file
* Bug: #87  - RoutingError (No route matches [GET] "/javascripts/jstoolbar/lang/jstoolbar-en-IS.js"):
* Bug: #103 - Multiple DMSF tabs in Administration->Custom fields & localization
* Bug: #110 - 'zip' gem conflicts with 'rubyzip' on Redmine XLS Export Plugin.
* Bug: #112 - Uninstall command
* Bug: #116 - Translation missing for DMSF custom field tabs
* Bug: #146 - Problem with Russian file names in zip
* Bug: #143 - Error on missing template - has to have to_s if adding to string
* Bug: #148 - I don't have a notification sent out when I upload a file
* Bug: #157 - Copying files/folders from one project to another project

1.4.5: *2012-07-20*
-------------------

* New: Settings introduced to enable read-only or read-write stance to be taken with webdav
* Bug: #27 - incorrect call to display column information from database (redmine 1.x fragment).
* Bug: #28 - incompatible SQL in db migration script for postgresql
* Bug: #23 - Incorrect call to to_s for displaying time in certain views
* Bug: #24 - Incorrect times shown on revision history / documents
* Bug: #25 - Character in init.rb stops execution
* Bug: #34 - Incorrect scope when accessing deleted files prevented notification.

1.4.4p2: *2012-07-08*
---------------------

* Bug: #22 - Webdav upload with passenger/nginx fails with server error (passenger class for request.body does not contain length method.
* Bug: Additional check implemented before reading settings to prevent server error when setting is not set and default does not apply.

1.4.4p1: *2012-07-07*
---------------------

* Bug: #20 - Listing not functional when using sqlite adapter
* Bug: #21 - Webdav not functional under bitnami (or sub directory)
* Bug: Testcase failed to cleanup after itself
* Bug: Webdav index object identified itself as having parent under prefix'ed path (in error)
* Bug: Addition of a path_prefix routine for webdav to be able to correct redirects

1.4.4: *2012-07-01*
-------------------

* New: Locking model updated to support shared and exclusive write locks. [At present UI and Webdav only support exclusive locking however]
* New: Folders are now write lockable (shared and exclusively) [UI upgraded to support folder locking, however only exclusively]
* New: Locks can now have a time-limit [Not yet supported from UI]
* New: Inereted lock support (locked folders child entries are now flagged as locked)
* Bug: Some testcases erroniously passed when files are locked, when they should be unlocked
* New: Webdav locks files for 1 hour at a time (requested time is ignored)
* New: Files are now stored in project relevent folder
* New: Implementation of lockdiscovery and supportedlock property requests
* New: Locks store a timestamp based UUID string enabling better interaction with webservices
* Bug: #16 - unable to add new project when plugin enabled due to bug in UI
* Bug: #17 - dav4rack not installable on some systems - it is now vendored
* Bug: #18 - Warnings thrown due to space between function and parentheses 

1.4.3: *2012-06-26*
-------------------

* New: Hook into project copy functionality to permit (although not attractively)
       functionality for DMSF to be duplicated accross projects
* New: Project patch defines linkage between DMSF files and DMSF folders.
* New: Data linkage allowing dependent items to be deleted (project deletion for example)
          this needs to be revised as files marked deleted are not affected by this at present
* New: README.md updated with Bundler requirement (Issue #13)
* Bug: Error in entity details page UI prevented revision management.

1.4.2: *2012-06-21*
-------------------

* New: Integration test cases for webdav functionality
* New: Documentation has been converted from Simpletext to Markdown
* New: Features listed in documentation
* Bug: #3 - "webdav broken until set in Administrator -> Settings"
* Bug: #5 - "Webdav incorrectly provides empty listing for non-DMSF enabled projects"
* Bug: Issues identified by test cases

1.4.1: *2012-06-15*
-------------------

* New: Dav4rack requirement added (Gemfile makes reference to github repository for latest release).
* New: Webdav functionality included, additional administrative settings added
* Bug: #2 - extended xapian search fixed with Rails 3 compatible code.

1.4.0: *2012-06-06*
-------------------

* New: Redmine 2.0 or higher is required