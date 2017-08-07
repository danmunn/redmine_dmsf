/* encoding: utf-8
 *
 * Redmine plugin for Document Management System "Features"
 *
 * Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

        var nextLinkId = dmsfAddLink.nextLinkId++;
        var linkSpan = $('<span>', { id: 'dmsf_links_attachments_' + nextLinkId, 'class': 'attachment' });
        var iconDel = $('<a>').attr({href: '#', 'class': 'remove-upload icon-only icon-del'});
        var inputId = $('<input>', {type: 'hidden', name: 'dmsf_links[' + nextLinkId + ']'}).val(linkId);
        var inputName = $('<input>', {type: 'text', class: 'filename readonly'}).val(linkName);

        linkSpan.append(inputId);
        linkSpan.append(inputName);
        linkSpan.append(iconDel.click(dmsfRemoveFileLbl));

        if(awf) {

            var iconWf = $('<a>').attr({href: "/dmsf_workflows/" + project + "/assign?dmsf_link_id=" + linkId,
                'class': 'modify-upload icon-only icon-wf-none', 'data-remote': 'true', 'title': title});

            linkSpan.append(iconWf);
        }

        linksSpan.append(linkSpan);
    }
}

dmsfAddLink.nextLinkId = 1000;

function dmsfAddFile(inputEl, file, eagerUpload) {

    if ($('#dmsf_attachments_fields').children().length < 10) {

        var attachmentId = dmsfAddFile.nextAttachmentId++;
        var fileSpan = $('<span>', { id: 'dmsf_attachments_' + attachmentId, 'class': 'attachment' });
        var iconDel = $('<a>').attr({href: '#', 'class': 'remove-upload icon-only icon-del'}).toggle(!eagerUpload);
        var fileName = $('<input>', {type: 'text', 'class': 'filename readonly',
            name: 'dmsf_attachments[' + attachmentId + '][filename]', readonly: 'readonly'}).val(file.name);

        if($(inputEl).attr('multiple') == 'multiple') {

            fileSpan.append(fileName);

            if($(inputEl).data('description')) {

                var description = $('<input>', {type: 'text', 'class': 'description',
                    name: 'dmsf_attachments[' + attachmentId + '][description]', maxlength: 255,
                    placeholder: $(inputEl).data('description-placeholder')
                }).toggle(!eagerUpload);

                fileSpan.append(description);
            }

            fileSpan.append(iconDel.click(dmsfRemoveFileLbl));

            if($(inputEl).data('awf')) {

                var iconWf = $('<a>').attr({href: '/dmsf_workflows/' + $(inputEl).attr(
                    'data-project') + "/assign?attachment_id=" + attachmentId, 'class': 'modify-upload icon-only icon-wf-none',
                    'data-remote': 'true'});

                fileSpan.append(iconWf);
            }

            $('#dmsf_attachments_fields').append(fileSpan);
        }
        else{
            fileSpan.append(fileName);
            $('#dmsf_attachments_fields').append(fileSpan);
            $('#dmsf_file_revision_name').val(file.name);
        }

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
            this.progressbar( 'value', e.loaded * 100 / e.total );
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
            var form = fileSpan.parents('form');
            if ((form.queue('upload').length == 0) && (dmsfAjaxUpload.uploading == 0)) {
                $('input:submit', form).removeAttr('disabled');
            }
            form.dequeue('upload');
        });
    }

    var progressSpan = $('<div>').insertAfter(fileSpan.find('input.filename'));
    progressSpan.progressbar();
    fileSpan.addClass('ajax-waiting');

    var maxSyncUpload = $(inputEl).data('max-concurrent-uploads');

    if(maxSyncUpload == null || maxSyncUpload <= 0 || dmsfAjaxUpload.uploading < maxSyncUpload)
        actualUpload(file, attachmentId, fileSpan, inputEl);
    else
        $(inputEl).parents('form').queue('upload', actualUpload.bind(this, file, attachmentId, fileSpan, inputEl));
}

dmsfAjaxUpload.uploading = 0;

function dmsfRemoveFileLbl() {

    $(this).parent('span').remove();

    return false;
}

function dmsfRemoveFile() {

    $(this).parent('span').parent('span').remove();

    return false;
}

function dmsfUploadBlob(blob, uploadUrl, attachmentId, options) {

    var actualOptions = $.extend({
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
            var xhr = $.ajaxSettings.xhr();
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

    var clearedFileInput = $(inputEl).clone().val('');
    var addFileSpan = $('.dmsf_add_attachment');

    if ($.ajaxSettings.xhr().upload && inputEl.files) {
        // upload files using ajax
        dmsfUploadAndAttachFiles(inputEl.files, inputEl);
        $(inputEl).remove();
    } else {
        // browser not supporting the file API, upload on form submission
        var attachmentId;
        var aFilename = inputEl.value.split(/\/|\\/);
        attachmentId = dmsfAddFile(inputEl, {name: aFilename[aFilename.length - 1]}, false);
        if (attachmentId) {
            $(inputEl).attr({name: 'dmsf_attachments[' + attachmentId + '][file]', style: 'display:none;'}).appendTo(
                '#dmsf_attachments_' + attachmentId);
        }
    }

    if ($(inputEl).attr('multiple') == 'multiple') {

        clearedFileInput.val('');
        addFileSpan.prepend(clearedFileInput);
    }
    else {

        addFileSpan.hide();
    }
}

function dmsfUploadAndAttachFiles(files, inputEl) {

    var maxFileSize = $(inputEl).data('max-file-size');
    var maxFileSizeExceeded = $(inputEl).data('max-file-size-message');

    var sizeExceeded = false;
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

        $.event.fixHooks.drop = { props: [ 'dataTransfer' ] };

        $('form span.dmsf_uploader').has('input:file').each(function() {
            $(this).on({
                dragover: dmsfDragOverHandler,
                dragleave: dmsfDragOutHandler,
                drop: dmsfHandleFileDropEvent
            });
        });
    }
}

$(document).ready(dmsfSetupFileDrop);
$(document).on("erui_new_dom", function() {
    dmsfSetupFileDrop();
});
