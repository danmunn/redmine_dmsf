/* Redmine plugin for Document Management System "Features"
*
* Karel Pičman <karel.picman@kontron.com>
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
function dmsfToggle(el, project_id, folder_id, url)
{
  // Expand not yet loaded selected row
  let selectedRow = $(el).parents('tr').first();
  let expand = $(selectedRow).hasClass('dmsf-collapsed');

  if(selectedRow.hasClass('dmsf-child')){

    return;
  }

  if(selectedRow.hasClass('dmsf-not-loaded')){

    dmsfExpandRows(project_id, folder_id, selectedRow, url);
  }

  let span = selectedRow.find('span.dmsf-expander');

  if(expand) {
    selectedRow.switchClass('dmsf-collapsed', 'dmsf-expanded');
    span.addClass('open');
  }
  else {
    selectedRow.switchClass('dmsf-expanded', 'dmsf-collapsed');
    span.removeClass('open');
  }

  // Hide collapsed rows and reset odd/even rows background colour
  let oddeventoggle = 0;

  $("tr.dmsf-tree").each(function(i, tr){

    // Visiblity
    if($(tr).hasClass(folder_id ? (folder_id + 'f') : (project_id + 'p'))) {
      if (expand) {

        // Display only children with expanded parent
        let m = $(tr).attr('class').match(/(\d+(p|f)) idnt/);

        if(m){

          if($("#" + m[1] + "span").hasClass('dmsf-expanded')){

            $(tr).removeClass('dmsf-hidden');
          }
        }

      } else {

        if(!$(tr).hasClass('dmsf-hidden')) {
          $(tr).addClass('dmsf-hidden');
        }
      }
    }

    // Background
    $(tr).removeClass('even');
    $(tr).removeClass('odd');

    if (oddeventoggle === 0) {

      $(tr).addClass('odd');
    }
    else {

      $(tr).addClass('even');
    }

    oddeventoggle ^= 1;
  });
}

/* Add child rows */
function dmsfExpandRows(project_id, folder_id, parentRow, url) {

  $(parentRow).removeClass('dmsf-not-loaded');

  let idnt = 0;
  let classes = '';
  let m = $(parentRow).attr('class').match(/idnt-(\d+)/);

  if(m){
    idnt = m[1];
  }

  m = $(parentRow).attr('class').match(/((\d|p|f|\s)+) idnt/);

  if(m){
      classes = m[1]
  }

  m = $(parentRow).attr('id').match(/^(\d+(p|f))/);

  if(m){
      classes = classes + ' ' + m[1]
  }

  $.ajax({
    url: url,
    type: 'post',
    dataType: 'html',
    data: {
      project_id: project_id,
      folder_id: folder_id,
      row_id: $(parentRow).attr('id'),
      idnt: idnt,
      classes: classes
    }
  }).done(function(data) {
      // Hide the expanding icon if there are no children
      if( m && (data.indexOf(' ' +  m[1] + ' ') < 0)) {

        $(parentRow).removeClass('dmsf-expanded');
	    $(parentRow).find('div.dmsf-row-control').removeClass('row-control dmsf-row-control');

        if(!$(parentRow).hasClass('dmsf-child')) {

          $(parentRow).addClass('dmsf-child');
        }
      }
      else {
        // Add child rows
        return Function('"use strict";' + data)();
      }
  })
  .fail(function() {
      console.log('An error in rows expanding');
  });
}

function noteMandatory(mandatory) {
  let note = $('textarea#note');
  note.prop('required', mandatory);
  if(mandatory){
    note.focus();
  }
}
