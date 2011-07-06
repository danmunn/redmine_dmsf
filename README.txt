Redmine DMSF is Document Management System Features plugin for Redmine issue tracking system.

It is aimed to replace current Redmine's Documents module.

Initial development was for Kontron AG R&D department and it is released as open source thanks to their generosity.

Project home: http://code.google.com/p/redmine-dmsf/

1. License

Redmine Document Management System "Features" plugin is distributed under GNU GPL version 2.

License itself is here: http://www.gnu.org/licenses/old-licenses/gpl-2.0.html#SEC1

2. Installation

2.1. Prerequisities

* Redmine 1.1.x
* Ruby Zip library - rubyzip gem

2.1.1. Fulltext search (optional) 

If you want to use fulltext search abilities:
* Xapian (http://xapian.org) search engine
* Xapian Omega indexing tool
* Xapian ruby bindings - xapian or xapian-full gem
 
To index some files with omega you may have to install some other packages like xpdf, antiword, ...

From Omega documentation:

    * PDF (.pdf) if pdftotext is available (comes with xpdf)
    * PostScript (.ps, .eps, .ai) if ps2pdf (from ghostscript) and pdftotext (comes with xpdf) are available
    * OpenOffice/StarOffice documents (.sxc, .stc, .sxd, .std, .sxi, .sti, .sxm, .sxw, .sxg, .stw) if unzip is available
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

On Debinan (Squeeze) use:
apt-get install libxapian-ruby1.8 xapian-omega libxapian-dev xpdf antiword unzip\
  catdoc libwpd8c2a libwps-0.1-1 gzip unrtf catdvi djview djview3

On Ubuntu use:
sudo apt-get install libxapian-ruby1.8 xapian-omega libxapian-dev xpdf antiword unzip\
  catdoc libwpd-0.9-9 libwps-0.2-2 gzip unrtf catdvi djview djview3

2.2. Setup/Upgrade

* In case of upgrade BACKUP YOUR DATABASE first
* Put redmine_dmsf plugin directory into vendor/plugins
* Initialize/Update database:
    rake db:migrate:plugins RAILS_ENV="production"
* The access rights must be set for web server, example: 
    chown -R www-data:www-data /opt/redmine/vendor/plugins/redmine_dmsf
* Restart web server
* You should configure plugin via Redmine interface: Administration -> Plugins -> DMSF -> Configure
* Assign DMSF permissions to appropriate roles

2.2.1. Fulltext search (optional)

If you want to use fulltext search features, you must setup file content indexing.

It is necessary to index DMSF files with omega before searching attemts to recieve some output:
    omindex -s english -l 1 --db {path to index database from  configuration} {path to storage from configuration}

This command must be run on regular basis (e.g. from cron)

Example of cron job (once per hour at 8th minute):
    * 8 * * * root /usr/bin/omindex -s english -l 1 --db /opt/redmine/files/dmsf_index /opt/redmine/files/dmsf

Use omindex -h for help.

2.3. Usage

DMSF act as project module so you must check DMSF in project settings.

Search options will now contain "Dmsf files" check, that allows you to search DMSF content.

There is possibility to link DMSF files from Wiki entries:
    {{dmsf(17)}} link to file with id 17
DMSF file id can be found in link for file download.

There is possibility to link DMSF folders from Wiki entries:
    {{dmsff(5)}} link to folder with id 5
DMSF folder id can be found in link for folder opening.

You can also publish Wiki help description. 
In file <redmine_root>/public/help/wiki_syntax_detailed.html include after document link description:
<ul>
    <li>
    	DMSF:
        <ul>
            <li><strong>{{dmsf(17)}}</strong> (link to file with id 17)</li>
            <li><strong>{{dmsff(5)}}</strong> (link to folder with id 5)</li>
        </ul>
        DMSF file id can be found in link for file download.<br />
        DMSF folder id can be found in link for folder opening.
    </li>
</ul>
