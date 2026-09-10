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
    window.addEventListener("dragover", (e) => {
        e.preventDefault();
        els.petWrapper.style.transform = HOVER_SCALE;
    });

    window.addEventListener("dragleave", (e) => {
        e.preventDefault();
        els.petWrapper.style.transform = "none";
    });

    window.addEventListener("drop", (e) => {
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
