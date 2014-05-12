Redmine DMSF Plugin
===================

The current version of Redmine DMSF is **1.4.8** [![Build Status](https://api.travis-ci.org/danmunn/redmine_dmsf.png)](https://travis-ci.org/danmunn/redmine_dmsf)

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
  * Optional document content fulltext search
  * Documents and folders symbolic links
  * Document tagging
  * Compatible with redmine 2.5.x

Dependencies
------------
  
  * Redmine 2.3.x or higher

### Fulltext search (optional)

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

```apt-get install libxapian-ruby1.9.1 xapian-omega libxapian-dev xpdf xpdf-utils antiword unzip\
 catdoc libwpd-0.9-9 libwps-0.2-2 gzip unrtf catdvi djview djview3 uuid uuid-dev```

On Ubuntu use:

```sudo apt-get install libxapian-ruby1.9.1 xapian-omega libxapian-dev xpdf antiword\
unzip catdoc libwpd-0.9-9 libwps-0.2-2 gzip unrtf catdvi djview djview3```

Usage
-----

DMSF is designed to act as project module, so it must be checked as an enabled module within the project settings.

Search will now automatically search DMSF content when a redmine search is performed, additionally a "Dmsf files" checkbox will be visible, allowing you to search DMSF content exclusively.

###Linking DMSF files from Wiki entries:

####Link to file with id 17:
`{{dmsf(17)}}`

####Link to file with id 17 with link text "File"
`{{dmsf(17,File)}}`

The DMSF file/revision id can be found in link for file/revision download from within redmine.

###Linking DMSF folders from Wiki entries:

####Link to folder with id 5:
`{{dmsff(5)}}`

####Link to folder with id 5 with link text "Folder"
`{{dmsff(5,Folder)}}`

The DMSF folder id can be found in the link when opening folders within Redmine.

You can also publish Wiki help description: 

In the file <redmine_root>/public/help/<language>/wiki_syntax_detailed.html, after the document link description/definition:

    <ul>
      <li>
        DMSF:
        <ul>
          <li><strong>{{dmsf(17)}}</strong> (link to file with id 17)</li>
          <li><strong>{{dmsf(17,File)}}</strong> (link to file with id 17 with link text "File")</li>
          <li><strong>{{dmsf(17,File,10)}}</strong> (link to file with id 17 with link text "File" and link pointing to revision 10)</li>
          <li><strong>{{dmsff(5)}}</strong> (link to folder with id 5)</li>
          <li><strong>{{dmsff(5,Folder)}}</strong> (link to folder with id 5 with link text "Folder")</li>
        </ul>
        The DMSF file/revision id can be found in link for file/revision download from within redmine.<br />
        The DMSF folder id can be found in the link when opening folders within Redmine.
      </li>
    </ul>

In the file <redmine_root>/public/help/<language>/wiki_syntax.html, at the end of the Redmine links section:

    <tr><th></th><td>{{dmsf(83)}}</td><td>Document <a href="#">#83</a></td></tr>


Setup / Upgrade
---------------

Before installing ensure that the Redmine instance is stopped.

1. In case of upgrade BACKUP YOUR DATABASE first
2. Put redmine_dmsf plugin directory into plugins
3. Initialize/Update database: `rake redmine:plugins:migrate RAILS_ENV="production"`
4. The access rights must be set for web server, example: `chown -R www-data:www-data plugins/redmine_dmsf`
5. Restart web server
6. You should configure plugin via Redmine interface: Administration -> Plugins -> DMSF -> Configure
7. Assign DMSF permissions to appropriate roles
8. There are two rake tasks:
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
If you want to use fulltext search features, you must setup file content indexing.

It is necessary to index DMSF files with omega before searching attemts to recieve some output:

    omindex -s english --url / --db {path to index database from configuration} {path to storage from configuration}

This command must be run on regular basis (e.g. from cron)

Example of cron job (once per hour at 8th minute):

    8 * * * * root /usr/bin/omindex -s english --url / --db /vat/tmp/dmsf_index /opt/redmine/files/dmsf

Use omindex -h for help.

Uninstalling DMSF
-----------------
Before uninstalling the DMSF plugin, please ensure that the Redmine instance is stopped.

1. `cd [redmine-install-dir]`
2. `rake redmine:plugins:migrate NAME=redmine_dmsf VERSION=0 RAILS_ENV=production`
3. `rm plugins/redmine_dmsf -Rf`

After these steps re-start your instance of Redmine.

Contributing
------------

If you've added something, why not share it. Fork the repository (github.com/danmunn/redmine_dmsf), make the changes and send a pull request to the maintainers.

Changes with tests, and full documentation are preferred.

Additional Documentation
------------------------

[CHANGELOG.md](CHANGELOG.md) - Project changelog