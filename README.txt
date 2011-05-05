1 License

Redmine Document Management System "Features" plugin is distributed under GNU GPL version 2.

License itself is here: http://www.gnu.org/licenses/old-licenses/gpl-2.0.html#SEC1

2 Installation and Setup

2.1. Required packages

For zipped content download you must have rubyzip gem installed.

To use file/document search capabilities you must install xapian (http://xapian.org) search engine. 
That means libxapian-ruby1.8 and xapian-omega packages. To index some files with omega you may have to install some other 
packages like xpdf, antiword, ...

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
apt-get install xapian-ruby1.8 xapian-omega libxapian-dev xpdf antiword unzip antiword\
  catdoc libwpd8c2a libwps-0.1-1 gzip unrtf catdvi djview djview3 libzip-ruby1.8

In case of package shortage it is possible to use:
gem install xapian-full rubyzip

2.2. Plugin installation

Install redmine_dmsf into vendor/plugins directory with:
* Put redmine_dmsf plugin content into vendor/plugins
* Initialize database:
	rake db:migrate:plugins RAILS_ENV="production"
* The access rights must be set for web server 
    Example:
    chown -R www-data:www-data /opt/redmine/vendor/plugins/redmine_dmsf
* Restart web server

2.3. Setup

Then you must configure plugin in Administration -> Plugins -> DMSF -> Configure

It is also neccessary to assign DMSF permissions to appropriate roles.

DMSF act as project module so you must check DMSF in project settings.

Search options will now contain "Dmsf files" check, that allows you to search DMSF content.

To include Wiki DMSF link help:
* In file public/help/wiki_syntax_detailed.html include after document link description:
<ul>
    <li>
    	DMSF:
        <ul>
            <li><strong>{{dmsf(17)}}</strong> (link to file with id 17)</li>
        </ul>
        DMSF file id can be found in link for file download
    </li>
</ul>

It is necessary to index DMSF files with omega before searching attemts to recieve some output:

omindex -s english -l 1 --db {path to index database from plugin configuration} {path to storage from plugin configuration}

This command must be run on regular basis (e.g. from cron)

Example of cron job (once per hour at 8th minute):
* 8 * * * root /usr/bin/omindex -s english -l 1 --db /opt/redmine/files/dmsf_index /opt/redmine/files/dmsf

Use omindex -h for help.
