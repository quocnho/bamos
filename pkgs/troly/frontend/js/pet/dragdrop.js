// ============================================================================
// pet/dragdrop.js — Kéo tệp từ file manager thả vào chú cún
// ----------------------------------------------------------------------------

import { els } from "../core/dom.js";
import { isAiWoken } from "../core/state.js";
import { setInputValue, focusInput } from "../chat/chat.js";
import { wake, happy, showBubble } from "./pet.js";

// Hệ số phóng to chú cún khi có tệp đang được kéo tới.
const HOVER_SCALE = "scale(1.08)";

export function initFileDrop() {
    // Bỏ qua khi người dùng đang kéo tệp vào vùng nạp của bảng thiết lập RAG.
    function isInsideDropzone(target) {
        return Boolean(
            target &&
            target.closest &&
            target.closest("#rag-dropzone, #rag-settings-modal"),
        );
    }

    window.addEventListener("dragover", (e) => {
        if (isInsideDropzone(e.target)) return;
        e.preventDefault();
        els.petWrapper.style.transform = HOVER_SCALE;
    });

    window.addEventListener("dragleave", (e) => {
        if (isInsideDropzone(e.target)) return;
        e.preventDefault();
        els.petWrapper.style.transform = "none";
    });

    window.addEventListener("drop", (e) => {
        if (isInsideDropzone(e.target)) return;
        e.preventDefault();
        els.petWrapper.style.transform = "none";

        if (!isAiWoken()) wake();

        if (
            e.dataTransfer &&
            e.dataTransfer.files &&
            e.dataTransfer.files.length > 0
        ) {
            const file = e.dataTransfer.files[0];
            happy();
            showBubble();
            setInputValue(`Đọc file ${file.name}`);
            focusInput();
        }
    });
}
