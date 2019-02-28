/* encoding: utf-8
*
* Redmine plugin for Document Management System "Features"
*
* Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/* Function to allow the projects to show up as a tree */
function dmsfToggle(EL, PM, url)
{
  var els = document.querySelectorAll('tr.dmsf_tree');
  var elsLen = els.length;
  var pattern = new RegExp("(^|\\s)" + EL + "(\\s|$)");
  var cpattern = new RegExp('span');
  var expand = new RegExp('dmsf_expanded');
  var collapse = new RegExp('dmsf_collapsed');
  var hide = new RegExp('dmsf_hidden');
  var spanid = PM;
  var classid = new RegExp('junk');
  var oddeventoggle = 0;

  // Expand not yet loaded selected row
  var selectedRow = document.getElementById(PM);

  if(selectedRow.className.indexOf('dmsf-not-loaded') >= 0){

    dmsfExpandRows(EL, selectedRow, url);
  }

  for(var i = 0; i < elsLen; i++)
  {
    if(cpattern.test(els[i].id))
    {
      var tmpspanid = spanid;
      var tmpclassid = classid;

      spanid = els[i].id;
      classid = spanid;
      classid = classid.match(/(\w+)span/)[1];
      classid = new RegExp(classid);

      if(tmpclassid.test(els[i].className) && (tmpspanid.toString() !== PM.toString()))
      {
        if(collapse.test(document.getElementById(tmpspanid).className))
        {
          spanid = tmpspanid;
          classid = tmpclassid;
        }
      }
    }

    if(pattern.test(els[i].className))
    {
      let cnames = els[i].className;

      cnames = cnames.replace(/dmsf_hidden/g,'');

      if(expand.test(selectedRow.className))
      {
        cnames += ' dmsf_hidden';
      }
      else
      {
        if((spanid.toString() !== PM.toString()) && (classid.test(els[i].className)))
        {
          if(collapse.test(document.getElementById(spanid).className))
          {
            cnames += ' dmsf_hidden';
          }
        }
      }

      els[i].className = cnames;
    }

    if(!(hide.test(els[i].className)))
    {
      let cnames = els[i].className;

      cnames = cnames.replace(/odd/g,'');
      cnames = cnames.replace(/even/g,'');

      if(oddeventoggle === 0)
      {
        cnames += ' odd';
      }
      else
      {
        cnames += ' even';
      }

      oddeventoggle ^= 1;
      els[i].className = cnames;
    }
  }

  if (collapse.test(selectedRow.className))
  {
    let cnames = selectedRow.className;

    cnames = cnames.replace(/dmsf_collapsed/,'dmsf_expanded');
    selectedRow.className = cnames;
  }
  else
  {
    let cnames = selectedRow.className;

    cnames = cnames.replace(/dmsf_expanded/,'dmsf_collapsed');
    selectedRow.className = cnames;
  }
}

/* Add child rows */
function dmsfExpandRows(EL, parentRow, url) {

  parentRow.className = parentRow.className.replace(/dmsf-not-loaded/, '');

  var idnt = 0;
  var result = parentRow.className.match(/idnt-(\d+)/);

  if(result){
    idnt = result[1];
  }

  var pos = $(parentRow).find('.dmsf_position').text();

  $.ajax({
    url: url,
    type: 'post',
    dataType: 'html',
    data: {
      folder_id: EL,
      row_id: parentRow.id,
      idnt: idnt,
      pos: pos}
  }).done(function(data) {
      eval(data);
  })
  .fail(function() {
      alert('An error in rows expanding');
  });
}

/* Plupload */
function initPlUploader(uploader, formUrl, maxFileSize, maxFileCount, flashUrl, silverLightUrl) {
    uploader.html('<div></div>');
    uploader = $('div', uploader);
    uploader.plupload({
        runtimes : 'html5,flash,silverlight,html4',
        url : formUrl,
        max_file_size : maxFileSize,
        max_file_count: maxFileCount,
        multipart: true,
        // Enable ability to drag'n'drop files onto the widget (currently only HTML5 supports that)
        dragdrop: true,
        multipart_params : { authenticity_token : $('input[name=authenticity_token]').val() },
        // Rename files by clicking on their titles
        rename: true,
        // Views to activate
        views: {
            list: true,
            thumbs: true, // Show thumbs
            active: 'thumbs'
        },
        // Flash settings
        flash_swf_url : flashUrl,
        // Silverlight settings
        silverlight_xap_url : silverLightUrl
    });
    $('.plupload_scroll', uploader).resizable({
        handles: 's'
    });
    var pluploader = uploader.plupload('getUploader');

    pluploader.bind('FileUploaded', function(pluploader, file, response) {
        var responseObject = $.parseJSON(response.response);
        if (responseObject == null) { //Bug: on Firefox folders entries act unexpectedly.
            file.status = plupload.FAILED;
            pluploader.trigger('UploadProgress', file);
            pluploader.trigger('QueueChanged');
        } else {
            if (responseObject.error == null) {
                var disk_filename_input = $('<input/>').attr('type', 'hidden')
                    .attr('name', 'uploaded[' + window.dmsfFileFieldCount + '][disk_filename]')
                    .val(responseObject.disk_filename);
                uploader.append(disk_filename_input);
                var content_type_input = $('<input/>').attr('type', 'hidden')
                    .attr('name', 'uploaded[' + window.dmsfFileFieldCount + '][content_type]')
                    .val(responseObject.content_type);
                uploader.append(content_type_input);
                var original_filename_input = $('<input/>').attr('type', 'hidden')
                    .attr('name', 'uploaded[' + window.dmsfFileFieldCount + '][original_filename]')
                    .val(responseObject.original_filename);
                uploader.append(original_filename_input);
                var tempfile_path = $('<input/>').attr('type', 'hidden')
                    .attr('name', 'uploaded[' + window.dmsfFileFieldCount + '][tempfile_path]')
                    .val(responseObject.tempfile_path);
                uploader.append(tempfile_path);
            } else {
                file.status = plupload.FAILED;
                pluploader.trigger('UploadProgress', file);
                pluploader.trigger('QueueChanged');
            }
        }
        if(pluploader.total.uploaded == pluploader.files.length) {
            $('#uploadform').submit();
        }
        else if((pluploader.total.uploaded + pluploader.total.failed) == pluploader.files.length) {
            setTimeout(function() {$('#uploadform').submit();}, 2000);
        }
        else {
            window.dmsfFileFieldCount++;
        }
        return true;
    });
}