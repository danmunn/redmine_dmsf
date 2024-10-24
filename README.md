Redmine DMSF Plugin 3.2.4
=========================

[![GitHub CI](https://github.com/danmunn/redmine_dmsf/actions/workflows/rubyonrails.yml/badge.svg?branch=master)](https://github.com/danmunn/redmine_dmsf/actions/workflows/rubyonrails.yml)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

Redmine DMSF is Document Management System Features plugin for Redmine issue tracking system; It is aimed to replace current Redmine's Documents module.

Redmine DMSF now comes bundled with WebDAV functionality: if switched on within plugin settings this will be accessible from _/dmsf/webdav_.

WebDAV functionality is provided through Dav4Rack library.

The development has been supported by [Kontron](https://www.kontron.com) and has been released as open source thanks to their generosity.  
Project home: <https://github.com/danmunn/redmine_dmsf>

Redmine Document Management System "Features" plugin is distributed under GNU General Public License v2 (GPL).  
Redmine is a flexible project management web application, released under the terms of the GNU General Public License v2 (GPL) at <https://www.redmine.org/>

Further information about the GPL license can be found at
<https://www.gnu.org/licenses/old-licenses/gpl-2.0.html#SEC1>

Features
--------

  * Directory structure
  * Document versioning / revision history 
  * Document locking
  * Multi (drag/drop depending on browser) upload/download  
  * Direct document or document link sending via email
  * Configurable document approval workflow
  * Document access auditing
  * Integration with Redmine's activity feed
  * Wiki macros for a quick content linking
  * Full read/write WebDAV functionality
  * Optional document content full-text search
  * Documents and folders' symbolic links  
  * Trash bin
  * Documents attachable to issues
  * Office documents are displayed inline
  * Editing of office documents
  * REST API
  * DMS Document revision as a custom field type
  * Compatible with Redmine 5.0.x

Dependencies
------------
  
  * Redmine 5.0 or higher

### Full-text search (optional)

#### Indexing

If you want to use full-text search features, you must setup file content indexing.

It is necessary to index DMSF files with omindex before searching attempts to receive some output:

1. Change the configuration part of redmine_dmsf/extra/xapian_indexer.rb file according to your environment.
   (The path to the index database set in xapian_indexer.rb must corresponds to the path set in the plugin's settings.)
2. Run `ruby redmine_dmsf/extra/xapian_indexer.rb -v`

This command should be run on regular basis (e.g. from cron)

Example of cron job (once per hour at 8th minute):

    8 * * * * root /usr/bin/ruby redmine_dmsf/extra/xapian_indexer.rb

See redmine_dmsf/extra/xapian_indexer.rb for help.

#### Searching

If you want to use fulltext search abilities, install xapian packages. In case of using of Bitnami 
stack or Ruby installed via RVM it might be necessary to install Xapian bindings from sources. See https://xapian.org
 for details. 

To index some files with omega you may have to install some other packages like
xpdf, antiword, ...

From Omega documentation:

   * HTML (.html, .htm, .shtml, .shtm, .xhtml, .xhtm)
   * PHP (.php) - our HTML parser knows to ignore PHP code
   * text files (.txt, .text)
   * SVG (.svg)
   * CSV (Comma-Separated Values) files (.csv)
   * PDF (.pdf) if pdftotext is available (comes with poppler or xpdf)
   * PostScript (.ps, .eps, .ai) if ps2pdf (from ghostscript) and pdftotext (comes with poppler or xpdf) are available
   * OpenOffice/StarOffice documents (.sxc, .stc, .sxd, .std, .sxi, .sti, .sxm, .sxw, .sxg, .stw) if unzip is available
   * OpenDocument format documents (.odt, .ods, .odp, .odg, .odc, .odf, .odb, .odi, .odm, .ott, .ots, .otp, .otg, .otc, .otf, .oti, .oth) if unzip is available
   * MS Word documents (.dot) if antiword is available (.doc files are left to libmagic, as they may actually be RTF (AbiWord saves RTF when asked to save as .doc, and Microsoft Word quietly loads RTF files with a .doc extension), or plain-text).
   * MS Excel documents (.xls, .xlb, .xlt, .xlr, .xla) if xls2csv is available (comes with catdoc)
   * MS Powerpoint documents (.ppt, .pps) if catppt is available (comes with catdoc)
   * MS Office 2007 documents (.docx, .docm, .dotx, .dotm, .xlsx, .xlsm, .xltx, .xltm, .pptx, .pptm, .potx, .potm, .ppsx, .ppsm) if unzip is available
   * Wordperfect documents (.wpd) if wpd2text is available (comes with libwpd)
   * MS Works documents (.wps, .wpt) if wps2text is available (comes with libwps)
   * MS Outlook message (.msg) if perl with Email::Outlook::Message and HTML::Parser modules is available
   * MS Publisher documents (.pub) if pub2xhtml is available (comes with libmspub)
   * AbiWord documents (.abw)
   * Compressed AbiWord documents (.zabw)
   * Rich Text Format documents (.rtf) if unrtf is available
   * Perl POD documentation (.pl, .pm, .pod) if pod2text is available
   * reStructured text (.rst, .rest) if rst2html is available (comes with docutils)
   * Markdown (.md, .markdown) if markdown is available
   * TeX DVI files (.dvi) if catdvi is available
   * DjVu files (.djv, .djvu) if djvutxt is available
   * XPS files (.xps) if unzip is available
   * Debian packages (.deb, .udeb) if dpkg-deb is available
   * RPM packages (.rpm) if rpm is available
   * Atom feeds (.atom)
   * MAFF (.maff) if unzip is available
   * MHTML (.mhtml, .mht) if perl with MIME::Tools is available
   * MIME email messages (.eml) and USENET articles if perl with MIME::Tools and HTML::Parser is available
   * vCard files (.vcf, .vcard) if perl with Text::vCard is available
    
You can use following commands to install some of the required indexing tools:    

On Debian use:

```
sudo apt-get install xapian-omega ruby-xapian libxapian-dev poppler-utils antiword unzip catdoc libwpd-tools \
libwps-tools gzip unrtf catdvi djview djview3 uuid uuid-dev xz-utils libemail-outlook-message-perl
```

On Ubuntu use:

```
sudo apt-get install xapian-omega ruby-xapian libxapian-dev poppler-utils antiword  unzip catdoc libwpd-tools \
libwps-tools gzip unrtf catdvi djview djview3 uuid uuid-dev xz-utils libemail-outlook-message-perl
```

On CentOS use:
```
sudo yum install xapian-core xapian-bindings-ruby libxapian-dev poppler-utils antiword unzip catdoc libwpd-tools \
libwps-tools gzip unrtf catdvi djview djview3 uuid uuid-dev xz libemail-outlook-message-perl
```

### Inline displaying of office documents (optional)

If LibreOffice binary `libreoffice` is present in the server, office documents (.odt, .ods,...) are displayed inline.
The command must be runable by the web app's user. Test it in advance, e.g:

`sudo -u www-data libreoffice --convert-to pdf my_document.odt`

`libreoffice` package is available in the most of Linux distributions, e.g. on Debain based systems:

```
sudo apt install libreoffice liblibreoffice-java
```            

Usage
-----

DMSF is designed to act as project module, so it must be checked as an enabled module within the project settings.

Search will now automatically search DMSF content when a Redmine search is performed, additionally a "Documents" and "Folders" check box will be visible, allowing you to search DMSF content exclusively.

Linking DMSF object from Wiki entries (macros)
---------------------------------------------

You can link DMSF object from Wikis using a macro tag `{{ }}`. List of available macros with their description is 
available from the wiki's toolbar.

Hooks
-----

You can implement these hooks in your plugin and extend DMSF functionality in certain events.

E.g.

    class DmsfUploadControllerHooks < Redmine::Hook::Listener

        def dmsf_upload_controller_after_commit(context={}) 
            context[:controller].flash[:info] = 'Okay'
        end

    end

**dmsf_upload_controller_after_commit**

Called after all uploaded files are committed.

parameters: *files*

**dmsf_helper_upload_after_commit**

Called after an individual file is committed. The controller is not available.

Parameters: *file*

**dmsf_workflow_controller_before_approval**

Called before an approval. If the hook returns false, the approval is not recorded.

parameters: *revision*, *step_action*

**dmsf_files_controller_before_view**

Allows a preview of the file by an external plugin. If the hook returns true, the file is not sent by DMSF. It is 
expected that the file is sent by the hook.

parameters: *file*

Setup / Upgrade
---------------

You can either clone the master branch or download the latest zipped version. Before installing ensure that the Redmine 
instance is stopped.

    git clone git@github.com:danmunn/redmine_dmsf.git
       
    wget https://github.com/danmunn/redmine_dmsf/archive/master.zip

1. In case of upgrade **BACKUP YOUR DATABASE, ORIGINAL PLUGIN AND THE FOLDER WITH DOCUMENTS** first!!!
2. Put redmine_dmsf plugin directory into plugins. The plugins sub-directory must be named just **redmine_dmsf**. In case
   of need rename _redmine_dmsf-x.y.z_ to *redmine_dmsf*.
3. **Go to the redmine directory** 

    `cd redmine`

4. Install dependencies: 

    `bundle install`

   4.1 In production environment

        bundle config set --local without 'development test`
        bundle install

   4.2 Without Xapian fulltext search (on Windows)

        bundle config set --local without 'xapian'
        bundle install

5. Initialize/Update database:

    `RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_dmsf`

6. The access rights must be set for web server, e.g.: 

    `chown -R www-data:www-data plugins/redmine_dmsf`.

7. Restart the web server, e.g.: 

    `systemctl restart apache2`

8. You should configure the plugin via Redmine interface: Administration -> Plugins -> DMSF -> Configure. (You should check and then save the plugin's configuration after each upgrade.)
9. Don't forget to grant permissions for DMSF in Administration -> Roles and permissions
10. Assign DMSF permissions to appropriate roles.
11. There are a few rake tasks:

    I) To convert documents from the standard Redmine document module

        Available options:

            * project - id or identifier of a project (default to all projects)
            * dry_run - perform just a check without any conversion
            * issues - Convert also files attached to issues

        Example:
            
            rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"

            (If you don't run the rake task as the web server user, don't forget to change the ownership of the imported files, e.g.
              chown -R www-data:www-data /redmine/files/dmsf
            afterwards)

    II) To alert all users who are expected to do an approval in the current approval steps

        Example:
            
            rake redmine:dmsf_alert_approvals RAILS_ENV="production"   
                        
    III) To create missing checksums for all document revisions
            
        Available options:
        
          * dry_run - test, no changes to the database          
          * forceSHA256 - replace old MD5 with SHA256
        
        Example:
        
          bundle exec rake redmine:dmsf_create_digests RAILS_ENV="production"
          bundle exec rake redmine:dmsf_create_digests forceSHA256=1 RAILS_ENV="production"
          bundle exec rake redmine:dmsf_create_digests dry_run=1 RAILS_ENV="production"
          
    IV) To maintain DMSF
        
        * Remove all files with no database record from the document directory
        * Remove all links project_id = -1 (added links to an issue which hasn't been created)
        
        Available options:
        
          * dry_run - No physical deletion but to list of all unused files only
        
        Example:
        
          rake redmine:dmsf_maintenance RAILS_ENV="production"
          rake redmine:dmsf_maintenance dry_run=1 RAILS_ENV="production"

### WebDAV

In order to enable WebDAV module, it is necessary to put the following code into yor `config/additional_environment.rb`

```ruby
# Redmine DMSF's WebDAV
require File.dirname(__FILE__) + '/plugins/redmine_dmsf/lib/redmine_dmsf/webdav/custom_middleware'
config.middleware.insert_before ActionDispatch::Cookies, RedmineDmsf::Webdav::CustomMiddleware
```

### Installation in a sub-uri

In order to documents and folders are available via WebDAV in case that the Redmine is configured to be run in a sub-uri 
it's necessary to add the following configuration option into your `config/additional_environment.rb`:

```ruby
config.relative_url_root = '/redmine'
```

Uninstalling DMSF
-----------------
Before uninstalling the DMSF plugin, please ensure that the Redmine instance is stopped.

1. `cd [redmine-install-dir]`
2. `rake redmine:plugins:migrate NAME=redmine_dmsf VERSION=0 RAILS_ENV=production`
3. `rm plugins/redmine_dmsf -Rf`

After these steps re-start your instance of Redmine.

Contributing
------------

If you've added something, why not share it. Fork the repository (github.com/danmunn/redmine_dmsf), 
make the changes and send a pull request to the maintainers.

Changes with tests, and full documentation are preferred.

Additional Documentation
------------------------

[CHANGELOG.md](CHANGELOG.md) - Project changelog

---

Special thanks to <a href="https://jetbrains.com"><img src="jetbrains-variant-3.svg" alt="JetBrains logo" width="59"  height="68"></a> for providing an excellent IDE.
