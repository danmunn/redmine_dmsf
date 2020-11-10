Changelog for Redmine DMSF
==========================

2.4.5 *2020-11-10*
------------------

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
* Bug: #1155 - Fix easy context menu
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
        
* New: #1072 - Fix deprecation multiple gemfile sources
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
* New #908   - Wrapping problem in Issue view

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
* New: #847 - REST API and delete Folder/document type: enhancement
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