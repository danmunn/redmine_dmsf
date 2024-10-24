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

function dmsfAddLink(linksSpan, linkId, linkName, title, project, awf) {

    if (linksSpan.children().length < 10) {

        let nextLinkId = dmsfAddLink.nextLinkId++;
        let linkSpan = $('<span>', { id: 'dmsf_links_attachments_' + nextLinkId, 'class': 'attachment' });
        let iconDel = $('<a>').attr({href: '#', 'class': 'remove-upload icon-only icon-del'});
        let inputId = $('<input>', {type: 'hidden', name: 'dmsf_links[' + nextLinkId + ']'}).val(linkId);
        let inputName = $('<input>', {type: 'text', class: 'filename readonly'}).val(linkName);

        linkSpan.append(inputId);
        linkSpan.append(inputName);
        linkSpan.append(iconDel.click(dmsfRemoveFileLbl));

        if(awf) {

            let iconWf = $('<a>').attr({href: "/dmsf-workflows/" + project + "/assign?dmsf_link_id=" + linkId,
                'class': 'modify-upload icon-only icon-ok', 'data-remote': 'true', 'title': title});

            linkSpan.append(iconWf);
        }

        linksSpan.append(linkSpan);
    }
}

dmsfAddLink.nextLinkId = 1000;

/* Remove the extension and replace underscores with spaces, 'after_init.rb' -> 'after init' */
function filenameToTitle(filename) {
    return filename.replace(/\.[^/.]+$/, "").replace(/_+/g, " ");
}

/* File size to human readable file size, 1024 -> 1.00 KB */
function humanFileSize(bytes) {
    var u = 0, s= 1024;
    while (bytes >= s || -bytes >= s) {
        bytes /= s;
        u++;
    }
    return (u ? bytes.toFixed(2) + ' ' : bytes) + ' KMGTPEZY'[u] + 'B';
}

/* Increase version */
function increaseVersion(version, max) {
    let res;
    if (version >= 0) {
        if ((version + 1) < max) {
            res = ++version;
        } else {
            res = version;
        }
    } else {
        if (-(version - 1) < 90 /* 'Z' */) {
            res = --version;
        } else
            res = version;
    }
    if (res < 0) {
        res = String.fromCharCode(-res);    // -65 => 'A'
    }
    return res;
}

/* Get next version */
function getNextVersion(filename, files) {
    for(let i = 0; i < files.length; i++) {
        if(filename === files[i][0]) {
            if(files[i][3] && (files[i][3] >= 0)) {
                return [files[i][1], files[i][2], increaseVersion(files[i][3], 1000)];
            }
            if(files[i][2] && (files[i][2] >= 0)) {
                return [files[i][1], increaseVersion(files[i][2], 1000), null];
            }
            return [increaseVersion(files[i][1], 100), null, null];
        }
    }
    return [0, 1, null];
}

/* Get the current version */
function getCurrentVersion(filename, files) {
    for(let i = 0; i < files.length; i++) {
        if (filename === files[i][0]) {
            let res = '';
            if (files[i][3] != null) {
                res = '.' + files[i][3];
            }
            if (files[i][2] != null) {
                res = '.' + files[i][2] + res;
            }
            if (files[i][1] != null) {
                res = files[i][1] + res;
            }
            return res;
        }
    }
    return '0.1.0';
}

/* Detects locked file */
function isFileLocked(filename, files) {
    for(let i = 0; i < files.length; i++) {
        if (filename === files[i][0]) {
            return files[i][4];
        }
    }
    return false;
}

/* Replace selected version */
function replaceVersion(detailsForm, attachmentId, name, version) {
    let index = detailsForm.search('id="committed_files_' + attachmentId + '_version_' + name + '"');
    if (index != -1) {
        let str = detailsForm.substring(index);
        // Remove the original selection
        str = str.replace('selected="selected" ', '');
        // Select new version
        if (version != null) {
            str = str.replace('<option value="' + version + '">' + version + '</option>', '<option selected="selected" value="' + version + '">' + version + '</option>');
        }
        else {
            let c = String.fromCharCode(160); // &nbsp;
            str = str.replace('<option value="">' + c + '</option>', '<option selected="selected" value="">' + c + '</option>');
        }
        detailsForm = detailsForm.substring(0, index) + str;
    }
    return detailsForm;
}

function dmsfAddFile(inputEl, file, eagerUpload) {

    let attachments = $('#dmsf_attachments_fields');
    let max = ($(inputEl).attr('multiple') == 'multiple') ? 10 : 1
    
    if (attachments.children('.attachment').length < max) {

        let attachmentId = dmsfAddFile.nextAttachmentId++;
        let fileSpan = $('<span>', { id: 'dmsf_attachments_' + attachmentId, 'class': 'attachment' });
        let iconDel = $('<a>').attr({href: '#', 'class': 'remove-upload icon-only icon-del'}).toggle(!eagerUpload);
        let fileName = $('<input>', {type: 'text', 'class': 'filename readonly',
            name: 'dmsf_attachments[' + attachmentId + '][filename]', readonly: 'readonly'}).val(file.name);

        fileSpan.append(fileName);

        if($(inputEl).attr('multiple') == 'multiple') {

            fileSpan.append(iconDel.click(dmsfRemoveFileLbl));

            if ($(inputEl).data('awf')) {

                let iconWf = $('<a>').attr({
                    href: '/dmsf-workflows/' + $(inputEl).attr(
                        'data-project') + "/assign?attachment_id=" + attachmentId,
                    'class': 'modify-upload icon-only icon-ok',
                    'data-remote': 'true'
                });

                fileSpan.append(iconWf);
            }

            // Details
            let detailsDiv = $('<div>').attr({id: 'dmsf_attachments_details_' + attachmentId});
            let detailsArrow = $('<a>');

            detailsArrow.text('[+]');
            detailsArrow.attr({href: "#", 'data-cy': 'toggle__new_revision_from_content--dmsf', title: 'Details'});
            detailsArrow.attr(
                {
                    onclick: "let newRevisionForm = $('#dmsf_attachments_details_" + attachmentId + "');" +
                        "let operator = newRevisionForm.is(':visible') ? '+' : '-';" +
                        "newRevisionForm.toggle();" +
                        "$(this).text('[' + operator + ']');" +
                        "$('#dmsf-upload-button').hide();" +
                        "return false;"
                });
            let files = $(inputEl).data('files');
            let locked = isFileLocked(file.name, files);
            let detailsForm = $(inputEl).data(locked ? 'dmsf-file-details-form-locked' : 'dmsf-file-details-form');

            // Index
            detailsForm = detailsForm.replace(/\[0\]/g, '[' + attachmentId + ']');
            detailsForm = detailsForm.replace(/_0/g, '_' + attachmentId);
            // Name
            detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_name" value=""',
                'id="committed_files_' + attachmentId + '_name" value="' + file.name + '"');
            // Title
            detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_title"',
                'id="committed_files_' + attachmentId + '_title" value = "' + filenameToTitle(file.name) + '"');
            // Size
            detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_human_size"',
                'id="committed_files_' + attachmentId + '_human_size" value = "' + humanFileSize(file.size) + '"');
            detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_size" value="0"',
                'id="committed_files_' + attachmentId + '_size" value = "' + file.size + '"');
            // Mime type
            detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_mime_type"',
                'id="committed_files_' + attachmentId + '_mime_type" value = "' + file.type + '"');
            // Version
            let version;
            if(locked) {
                version = getCurrentVersion(file.name, files);
                detailsForm = detailsForm.replace('id="committed_files_' + attachmentId + '_version" value="0.0"',
                    'id="committed_files_' + attachmentId + '_version" value="' + version + '"');
            } else {
                version = getNextVersion(file.name, files);
                detailsForm = replaceVersion(detailsForm, attachmentId, 'patch', version[2]);
                detailsForm = replaceVersion(detailsForm, attachmentId, 'minor', version[1]);
                detailsForm = replaceVersion(detailsForm, attachmentId, 'major', version[0]);
            }

            detailsDiv.append(detailsForm);
            detailsDiv.hide();

            fileSpan.append(detailsArrow)
            attachments.append(fileSpan);
            attachments.append(detailsDiv);
        } else {
            fileSpan.append(iconDel.click(dmsfRemoveFileLbl));
            attachments.append(fileSpan);
            $('#dmsf_file_revision_name').val(file.name);
        }
        attachments.append('<br>');

        if(eagerUpload) {
            dmsfAjaxUpload(file, attachmentId, fileSpan, inputEl);
        }

        return attachmentId;
    }
    return null;
}

dmsfAddFile.nextAttachmentId = 1;

function dmsfAjaxUpload(file, attachmentId, fileSpan, inputEl) {

    function onLoadstart(e) {
        fileSpan.removeClass('ajax-waiting');
        fileSpan.addClass('ajax-loading');
        $('input:submit', $(this).parents('form')).attr('disabled', 'disabled');
    }

    function onProgress(e) {
        if(e.lengthComputable) {
            this.progressbar('value', e.loaded * 100 / e.total);
        }
    }

    function actualUpload(file, attachmentId, fileSpan, inputEl) {

        dmsfAjaxUpload.uploading++;

        dmsfUploadBlob(file, $(inputEl).data('upload-path'), attachmentId, {
            loadstartEventHandler: onLoadstart.bind(progressSpan),
            progressEventHandler: onProgress.bind(progressSpan)
        })
            .done(function(result) {
                progressSpan.progressbar( 'value', 100 ).remove();
                fileSpan.find('input.description, a').css('display', 'inline-block');
            })
            .fail(function(result) {
                progressSpan.text(result.statusText);
            }).always(function() {
                dmsfAjaxUpload.uploading--;
                fileSpan.removeClass('ajax-loading');
                let form = fileSpan.parents('form');
                if ((form.queue('upload').length == 0) && (dmsfAjaxUpload.uploading == 0)) {
                    $('input:submit', form).removeAttr('disabled');
            }
            form.dequeue('upload');
        });
    }

    let progressSpan = $('<div>').insertAfter(fileSpan.find('input.filename'));
    progressSpan.progressbar();
    fileSpan.addClass('ajax-waiting');

    let maxSyncUpload = $(inputEl).data('max-concurrent-uploads');

    if(maxSyncUpload == null || maxSyncUpload <= 0 || dmsfAjaxUpload.uploading < maxSyncUpload)
        actualUpload(file, attachmentId, fileSpan, inputEl);
    else
        $(inputEl).parents('form').queue('upload', actualUpload.bind(this, file, attachmentId, fileSpan, inputEl));
}

dmsfAjaxUpload.uploading = 0;

function dmsfRemoveFileLbl() {

    let span = $(this).parent('span');

    span.next('div').remove();
    span.next('br').remove();
    span.remove();

    return false;
}

function dmsfUploadBlob(blob, uploadUrl, attachmentId, options) {

    let actualOptions = $.extend({
        loadstartEventHandler: $.noop,
        progressEventHandler: $.noop
    }, options);

    uploadUrl = uploadUrl + '?attachment_id=' + attachmentId;
    if (blob instanceof window.File) {
        uploadUrl += '&filename=' + encodeURIComponent(blob.name);
        uploadUrl += '&content_type=' + encodeURIComponent(blob.type);
    }

    return $.ajax(uploadUrl, {
        type: 'POST',
        contentType: 'application/octet-stream',
        beforeSend: function(jqXhr, settings) {
            jqXhr.setRequestHeader('Accept', 'application/js');
            // attach proper File object
            settings.data = blob;
        },
        xhr: function() {
            let xhr = $.ajaxSettings.xhr();
            xhr.upload.onloadstart = actualOptions.loadstartEventHandler;
            xhr.upload.onprogress = actualOptions.progressEventHandler;
            return xhr;
        },
        data: blob,
        cache: false,
        processData: false
    });
}

function dmsfAddInputFiles(inputEl) {

    let clearedFileInput = $(inputEl).clone().val('');
    let addFileSpan = $('.dmsf_add_attachment');

    if ($.ajaxSettings.xhr().upload && inputEl.files) {
        // upload files using ajax
        dmsfUploadAndAttachFiles(inputEl.files, inputEl);
        $(inputEl).remove();
    } else {
        // browser not supporting the file API, upload on form submission
        let attachmentId;
        let aFilename = inputEl.value.split(/\/|\\/);
        attachmentId = dmsfAddFile(inputEl, {name: aFilename[aFilename.length - 1]}, false);
        if (attachmentId) {
            $(inputEl).attr({name: 'dmsf_attachments[' + attachmentId + '][file]', style: 'display:none;'}).appendTo(
                '#dmsf_attachments_' + attachmentId);
        }
    }

    clearedFileInput.val('');
    addFileSpan.prepend(clearedFileInput);
}

function dmsfUploadAndAttachFiles(files, inputEl) {

    let maxFileSize = $(inputEl).data('max-file-size');
    let maxFileSizeExceeded = $(inputEl).data('max-file-size-message');
    let sizeExceeded = false;

    $.each(files, function() {
        if (this.size && maxFileSize != null && this.size > parseInt(maxFileSize)) {sizeExceeded=true;}
    });
    if (sizeExceeded) {
        window.alert(maxFileSizeExceeded);
    } else {
        $.each(files, function() {
            dmsfAddFile(inputEl, this, true);
        });
    }
}

function dmsfHandleFileDropEvent(e) {

    $(this).removeClass('fileover');
    blockEventPropagation(e);

    if ($.inArray('Files', e.dataTransfer.types) > -1) {
        dmsfUploadAndAttachFiles(e.dataTransfer.files, $('input:file.file_selector'));
    }
}

function dmsfDragOverHandler(e) {
    $(this).addClass('fileover');
    blockEventPropagation(e);
}

function dmsfDragOutHandler(e) {
    $(this).removeClass('fileover');
    blockEventPropagation(e);
}

function dmsfSetupFileDrop() {

    if (window.File && window.FileList && window.ProgressEvent && window.FormData) {

        if($().jquery < '3.0.0') {
            $.event.fixHooks.drop = {props: ['dataTransfer']};
        }
        else{
            $.event.addProp('dataTransfer');
        }

        $('form span.dmsf-uploader:not(.dmsffiledroplistner)').has('input:file').each(function () {

            $(this).on({
                dragover: dmsfDragOverHandler,
                dragleave: dmsfDragOutHandler,
                drop: dmsfHandleFileDropEvent
            }).addClass('dmsffiledroplistner');
        });
    }
}

if(typeof EASY == "undefined"){
    $(document).ready(dmsfSetupFileDrop);
}
else {
    EASY.schedule.late(function () {
        dmsfSetupFileDrop();
        $(document).on("erui_new_dom", dmsfSetupFileDrop);
    });
}
