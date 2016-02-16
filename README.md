Redmine DMSF Plugin
===================

The current version of Redmine DMSF is **1.5.6** [![Build Status](https://api.travis-ci.org/danmunn/redmine_dmsf.png)](https://travis-ci.org/danmunn/redmine_dmsf)

Redmine DMSF is Document Management System Features plugin for Redmine issue tracking system; It is aimed to replace current Redmine's Documents module.

Redmine DMSF now comes bundled with Webdav functionality: if switched on within plugin settings this will be accessible from /dmsf/webdav.

Webdav functionality is provided through DAV4Rack gem.

Initial development was for Kontron AG R&D department and it is released as open source thanks to their generosity.  
Project home: <http://code.google.com/p/redmine-dmsf/>

Redmine Document Management System "Features" plugin is distributed under GNU General Public License v2 (GPL).  
Redmine is a flexible project management web application, released under the terms of the GNU General Public License v2 (GPL) at <http://www.redmine.org/>

Further information about the GPL license can be found at
<http://www.gnu.org/licenses/old-licenses/gpl-2.0.html#SEC1>

Features
--------

  * Directory structure
  * Document versioning / revision history
  * Email notifications for directories and/or documents
  * Document locking
  * Multi (drag/drop depending on browser) upload/download
  * Multi download via zip
  * Direct document or document link sending via email
  * Configurable document approval workflow
  * Document access auditing
  * Integration with Redmine's activity feed
  * Wiki macros for quick content linking
  * Full read/write webdav functionality
  * Optional document content full-text search
  * Documents and folders symbolic links
  * Document tagging
  * Trash bin
  * Compatible with Redmine 3.x.x

Dependencies
------------
  
  * Redmine 3.0.0 or higher

### Full-text search (optional)

If you want to use fulltext search abilities:

  * Xapian (<http://www.xapian.org/>) search engine 
  * Xapian Omega indexing tool
  * Xapian ruby bindings - xapian or xapian-full gem

To index some files with omega you may have to install some other packages like
xpdf, antiword, ...

From Omega documentation:

    * PDF (.pdf) if pdftotext is available (comes with xpdf)  
    * PostScript (.ps, .eps, .ai) if ps2pdf (from ghostscript) and pdftotext (comes with xpdf) are available  
    * OpenOffice/StarOffice documents (.sxc, .stc, .sxd, .std, .sxi, .sti, .sxm, .sxw, .sxg, .stw) if unzip is available.
    * OpenDocument format documents (.odt, .ods, .odp, .odg, .odc, .odf, .odb, .odi, .odm, .ott, .ots, .otp, .otg, .otc, .otf, .oti, .oth) if unzip is available  
    * MS Word documents (.doc, .dot) if antiword is available  
    * MS Excel documents (.xls, .xlb, .xlt) if xls2csv is available (comes with catdoc)  
    * MS Powerpoint documents (.ppt, .pps) if catppt is available (comes with catdoc)  
    * MS Office 2007 documents (.docx, .dotx, .xlsx, .xlst, .pptx, .potx, .ppsx) if unzip is available  
    * Wordperfect documents (.wpd) if wpd2text is available (comes with libwpd)  
    * MS Works documents (.wps, .wpt) if wps2text is available (comes with libwps)  
    * AbiWord documents (.abw)  
    * Compressed AbiWord documents (.zabw) if gzip is available  
    * Rich Text Format documents (.rtf) if unrtf is available  
    * Perl POD documentation (.pl, .pm, .pod) if pod2text is available  
    * TeX DVI files (.dvi) if catdvi is available  
    * DjVu files (.djv, .djvu) if djvutxt is available  
    * XPS files (.xps) if unzip is available

On Debian use:

```sudo apt-get install xapian-omega libxapian-dev xpdf xpdf-utils \
 antiword unzip catdoc libwpd-tools libwps-tools gzip unrtf catdvi \
 djview djview3 uuid uuid-dev xz-utils```

On Ubuntu use:

```sudo apt-get install xapian-omega libxapian-dev xpdf xpdf-utils antiword \
 unzip catdoc libwpd-tools libwps-tools gzip unrtf catdvi djview djview3 \
 uuid uuid-dev xz-utils```

On CentOS user:
```sudo yum install xapian-omega libxapian-dev xpdf xpdf-utils antiword \
 unzip catdoc libwpd-tools libwps-tools gzip unrtf catdvi djview djview3 \
 uuid uuid-dev xz```

Usage
-----

DMSF is designed to act as project module, so it must be checked as an enabled module within the project settings.

Search will now automatically search DMSF content when a Redmine search is performed, additionally a "Documents" and "Folders" check box will be visible, allowing you to search DMSF content exclusively.

###Linking DMSF files from Wiki entries:

####Link to a file with id 17:
`{{dmsf(17)}}`

####Link to a file with id 17 with link text "File"
`{{dmsf(17, File)}}`

####Link to the description of a file with id 17
`{{dmsfd(17)}}`

####Link to the preview of the first 5 lines from a file with id 17
`{{dmsft(17, 5)}}`

####An inline picture of the file with id 8; it must be an image file such as JPEG, PNG,...
`{{dmsf_image(8)}}`

####An inline picture with custom size
`{{dmsf_image(8, size=300)}}`

####An inline picture with custom size
`{{dmsf_image(8, size=50%)}}`

####An inline picture with custom size
`{{dmsf_image(8, size=640x480)}}`

The DMSF file/revision id can be found in link for file/revision download from within Redmine.

###Linking DMSF folders from Wiki entries:

####Link to a folder with id 5:
`{{dmsff(5)}}`

####Link to a folder with id 5 with link text "Folder"
`{{dmsff(5, Folder)}}`

The DMSF folder id can be found in the link when opening folders within Redmine.

You can also publish Wiki help description: 

In the file <redmine_root>/public/help/<language>/wiki_syntax_detailed.html, after the document link description/definition:

    <ul>
      <li>
        DMSF:
        <ul>
          <li><strong>{{dmsf(17)}}</strong> (a link to the file with id 17)</li>
          <li><strong>{{dmsf(17, File)}}</strong> (a link to the file with id 17 with the link text "File")</li>
          <li><strong>{{dmsf(17, File, 10)}}</strong> (a link to the file with id 17 with the link text "File" and the link pointing to the revision 10)</li>
          <li><strong>{{dmsfd(17)}}</strong> (a link to the description of the file with id 17)</li>
          <li><strong>{{dmsff(5)}}</strong> (a link to the folder with id 5)</li>
          <li><strong>{{dmsff(5, Folder)}}</strong> (a link to the folder with id 5 with the link text "Folder")</li>
          <li><strong>{{dmsf_image(8)}}</strong> (an inline picture of the file with id 8; it must be an image file such as JPEG, PNG,...)</li>
          <li><strong>{{dmsf_image(8, size=300)}}</strong> (an inline picture with custom size)</li>
          <li><strong>{{dmsf_image(8, size=640x480)}}</strong> (an inline picture with custom size)</li>
        </ul>
        The DMSF file/revision id can be found in the link for file/revision download from within Redmine.<br />
        The DMSF folder id can be found in the link when opening folders within Redmine.
      </li>
    </ul>

In the file <redmine_root>/public/help/<language>/wiki_syntax.html, at the end of the Redmine links section:

    <tr><th></th><td>{{dmsf(83)}}</td><td>Document <a href="#">#83</a></td></tr>    

There's a patch that helps you to modify all help files at once. In your Redmine folder:

`cd redmine`

`patch -p0 < plugins/redmine_dmsf/extra/help_files_dmsf.diff`


Setup / Upgrade
---------------

Before installing ensure that the Redmine instance is stopped.

1. In case of upgrade BACKUP YOUR DATABASE first
2. Put redmine_dmsf plugin directory into plugins.
3. Install dependencies: `bundle install`.
4. Initialize/Update database: `bundle exec rake redmine:plugins:migrate RAILS_ENV="production"`.
5. The access rights must be set for web server, example: `chown -R www-data:www-data plugins/redmine_dmsf`.
6. Restart the web server.
7. You should configure the plugin via Redmine interface: Administration -> Plugins -> DMSF -> Configure.
8. Assign DMSF permissions to appropriate roles.
9. There are two rake tasks:

    a) To convert documents from the standard Redmine document module

        Available options:

            * project  => id or identifier of project (defaults to all projects)
            * dry  => true or false (default false) to perform just check without any conversion
            * invalid=replace  => to perform document title invalid characters replacement for '-'

        Example:
            
            rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"

    b) To alert all users who are expected to do an approval in the current approval steps

        Example:
            
            rake redmine:dmsf_alert_approvals RAILS_ENV="production"            

### Fulltext search (optional)
If you want to use full-text search features, you must setup file content indexing.

It is necessary to index DMSF files with omega before searching attempts to receive some output:

  1. Change the configuration part of redmine_dmsf/extra/xapian_indexer.rb file according to your environment.
  2. Run `ruby redmine_dmsf/extra/xapian_indexer.rb -f`

This command must be run on regular basis (e.g. from cron)

Example of cron job (once per hour at 8th minute):
    
    8 * * * * root /usr/bin/ruby redmine_dmsf/extra/xapian_indexer.rb -f

See redmine_dmsf/extra/xapian_indexer.rb for help.

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
[dmsf_user_guide.odt](dmsf_user_guide.odt) - User's guide
