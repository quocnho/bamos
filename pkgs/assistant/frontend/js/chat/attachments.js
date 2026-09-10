// ============================================================================
// chat/attachments.js — Quản lý tệp/hình ảnh đính kèm
// ----------------------------------------------------------------------------
// Chịu trách nhiệm chọn tệp, đọc nội dung (text hoặc data URL cho ảnh) và
// hiển thị thanh xem trước. Module này không quan tâm nội dung sẽ được gửi đi
// thế nào — chat.js sẽ lấy dữ liệu qua consume().
// ============================================================================

import { els, show, hide } from "../core/dom.js";

/**
 * Tạo bộ quản lý đính kèm.
 * @returns {{bind: Function, clear: Function, consume: Function, peek: Function}}
 */
export function createAttachmentManager() {
    // { name: string, content: string, type: 'file' | 'image' }
    let current = null;

    function clear() {
        current = null;
        if (els.fileUploadInput) els.fileUploadInput.value = "";
        hide(els.attachedPreviewBar);
    }

    /** Lấy đính kèm hiện tại rồi xoá khỏi giao diện (gọi ngay trước khi gửi). */
    function consume() {
        const attachment = current;
        if (attachment) clear();
        return attachment;
    }

    function peek() {
        return current;
    }

    function applyFile(file) {
        const isImage = file.type.startsWith("image/");
        const reader = new FileReader();

        reader.onload = (event) => {
            current = {
                name: file.name,
                type: isImage ? "image" : "file",
                content: event.target.result, // chuỗi text hoặc data URL
            };
            if (els.attachedIcon)
                els.attachedIcon.textContent = isImage ? "🖼️" : "📄";
            if (els.attachedFilename)
                els.attachedFilename.textContent = file.name;
            show(els.attachedPreviewBar);
            if (els.chatInput) els.chatInput.focus();
        };

        if (isImage) {
            reader.readAsDataURL(file);
        } else {
            reader.readAsText(file);
        }
    }

    function bind() {
        if (els.btnAttach) {
            els.btnAttach.addEventListener("click", (e) => {
                e.stopPropagation();
                els.fileUploadInput.click();
            });
        }

        if (els.fileUploadInput) {
            els.fileUploadInput.addEventListener("change", (e) => {
                if (e.target.files && e.target.files.length > 0) {
                    applyFile(e.target.files[0]);
                }
            });
        }

        if (els.btnRemoveAttachment) {
            els.btnRemoveAttachment.addEventListener("click", clear);
        }
    }

    return { bind, clear, consume, peek };
}
