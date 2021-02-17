/* encoding: utf-8
 *
 * Redmine plugin for Document Management System "Features"
 *
 * Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

function dmsfAddFile(inputEl, file, eagerUpload) {

    let attachments = $('#dmsf_attachments_fields');

    if (attachments.children().length < 10) {

        let attachmentId = dmsfAddFile.nextAttachmentId++;
        let fileSpan = $('<span>', { id: 'dmsf_attachments_' + attachmentId, 'class': 'attachment' });
        let iconDel = $('<a>').attr({href: '#', 'class': 'remove-upload icon-only icon-del'}).toggle(!eagerUpload);
        let fileName = $('<input>', {type: 'text', 'class': 'filename readonly',
            name: 'dmsf_attachments[' + attachmentId + '][filename]', readonly: 'readonly'}).val(file.name);

        if($(inputEl).attr('multiple') == 'multiple') {

            fileSpan.append(fileName);

            if($(inputEl).data('description')) {

                let description = $('<input>', {type: 'text', 'class': 'description',
                    name: 'dmsf_attachments[' + attachmentId + '][description]', maxlength: 255,
                    placeholder: $(inputEl).data('description-placeholder')
                }).toggle(!eagerUpload);

                fileSpan.append(description);
            }

            fileSpan.append(iconDel.click(dmsfRemoveFileLbl));

            if($(inputEl).data('awf')) {

                let iconWf = $('<a>').attr({href: '/dmsf-workflows/' + $(inputEl).attr(
                    'data-project') + "/assign?attachment_id=" + attachmentId, 'class': 'modify-upload icon-only icon-ok',
                    'data-remote': 'true'});

                fileSpan.append(iconWf);
            }

            attachments.append(fileSpan);
        }
        else{
            fileSpan.append(fileName);
            attachments.append(fileSpan);
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

    $(this).parent('span').remove();

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

    if ($(inputEl).attr('multiple') == 'multiple') {

        clearedFileInput.val('');
        addFileSpan.prepend(clearedFileInput);
    }
    else {

        addFileSpan.hide();
    }
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

EASY.schedule.late(function () {
    dmsfSetupFileDrop();
    $(document).on("erui_new_dom", dmsfSetupFileDrop);
});

