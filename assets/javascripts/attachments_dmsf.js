/* Redmine - project management software
 Copyright (C) 2006-2016  Jean-Philippe Lang */

function dmsfAddFile(inputEl, file, eagerUpload) {

    if ($('#dmsf_attachments_fields').children().length < 10) {

        var attachmentId = dmsfAddFile.nextAttachmentId++;

        var fileSpan = $('<span>', { id: 'dmsf_attachments_' + attachmentId });

        fileSpan.append(
            $('<input>', { type: 'text', 'class': 'filename readonly', name: 'dmsf_attachments[' + attachmentId + '][filename]', readonly: 'readonly'} ).val(file.name),
            $('<input>', { type: 'text', 'class': 'description', name: 'dmsf_attachments[' + attachmentId + '][description]', maxlength: 255, placeholder: $(inputEl).data('description-placeholder') } ).toggle(!eagerUpload),
            $('<a>&nbsp</a>').attr({ href: "#", 'class': 'remove-upload' }).click(dmsfRemoveFile).toggle(!eagerUpload)
        ).appendTo('#dmsf_attachments_fields');

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
            if (form.queue('upload').length == 0 && dmsfAjaxUpload.uploading == 0) {
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

function dmsfRemoveFile() {
    $(this).parent('span').remove();
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

    if ($.ajaxSettings.xhr().upload && inputEl.files) {
        // upload files using ajax
        dmsfUploadAndAttachFiles(inputEl.files, inputEl);
        $(inputEl).remove();
    } else {
        // browser not supporting the file API, upload on form submission
        var attachmentId;
        var aFilename = inputEl.value.split(/\/|\\/);
        attachmentId = dmsfAddFile(inputEl, { name: aFilename[ aFilename.length - 1 ] }, false);
        if (attachmentId) {
            $(inputEl).attr({ name: 'dmsf_attachments[' + attachmentId + '][file]', style: 'display:none;' }).appendTo('#dmsf_attachments_' + attachmentId);
        }
    }

    clearedFileInput.insertAfter('#dmsf_attachments_fields');
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
        $.each(files, function() {dmsfAddFile(inputEl, this, true);});
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

        $('form div.dmsf_uploader').has('input:file').each(function() {
            $(this).on({
                dragover: dmsfDragOverHandler,
                dragleave: dmsfDragOutHandler,
                drop: dmsfHandleFileDropEvent
            });
        });
    }
}

$(document).ready(dmsfSetupFileDrop);
