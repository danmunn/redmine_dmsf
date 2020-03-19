/* encoding: utf-8
*
* Redmine plugin for Document Management System "Features"
*
* Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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
  let els = document.querySelectorAll('tr.dmsf-tree');
  let elsLen = els.length;
  let pattern = new RegExp("(^|\\s)" + EL + "(\\s|$)");
  let cpattern = new RegExp('span');
  let expand = new RegExp('dmsf_expanded');
  let collapse = new RegExp('dmsf_collapsed');
  let hide = new RegExp('dmsf-hidden');
  let spanid = PM;
  let classid = new RegExp('junk');
  let oddeventoggle = 0;

  // Expand not yet loaded selected row
  let selectedRow = document.getElementById(PM);

  if(selectedRow.className.indexOf('dmsf-not-loaded') >= 0){

    dmsfExpandRows(EL, selectedRow, url);
  }

  for(let i = 0; i < elsLen; i++)
  {
    if(cpattern.test(els[i].id))
    {
      let tmpspanid = spanid;
      let tmpclassid = classid;

      spanid = els[i].id;
      classid = spanid;
      let m = classid.match(/(\w+)span/);
      if(m) {
          classid = m[1];
      }
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

      cnames = cnames.replace(/dmsf-hidden/g,'');

      if(expand.test(selectedRow.className))
      {
        cnames += ' dmsf-hidden';
      }
      else
      {
        if((spanid.toString() !== PM.toString()) && (classid.test(els[i].className)))
        {
          if(collapse.test(document.getElementById(spanid).className))
          {
            cnames += ' dmsf-hidden';
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

  let idnt = 0;
  let pos = $(parentRow).find('.dmsf_position').text();
  let classes = '';
  let m = parentRow.className.match(/idnt-(\d+)/);

  if(m){
    idnt = m[1];
  }

  m = parentRow.className.match(/((\d|\s)+) idnt/);

  if(m){
      classes = m[1]
  }

  m = parentRow.id.match(/^(\d+)/);

  if(m){
      classes = classes + ' ' + m[1]
  }

  $.ajax({
    url: url,
    type: 'post',
    dataType: 'html',
    data: {
      folder_id: EL,
      row_id: parentRow.id,
      idnt: idnt,
      pos: pos,
      classes: classes
    }
  }).done(function(data) {
      eval(data);
  })
  .fail(function() {
      alert('An error in rows expanding');
  });
}
