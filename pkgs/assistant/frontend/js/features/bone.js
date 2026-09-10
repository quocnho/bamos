// ============================================================================
// features/bone.js — "Cục Xương": bối cảnh thư mục làm việc
// ----------------------------------------------------------------------------
// Khi người dùng gửi một thư mục từ Nautilus/CLI, backend sẽ gọi
// window.setDirectoryContext(dir). Module này hiển thị thanh bối cảnh, thông
// báo cho backend và mở sẵn cuộc trò chuyện.
// ============================================================================

import { els, show, hide } from "../core/dom.js";
import { native } from "../core/native.js";
import { escapeHtml } from "../core/utils.js";
import { isAiWoken, getAddressing } from "../core/state.js";
import { wake, happy, showBubble } from "../pet/pet.js";
import { showMessage, focusInput, setPlaceholder } from "../chat/chat.js";

const DEFAULT_PLACEHOLDER = "Nói chuyện cùng em... (Enter để gửi)";

/** Nạp bối cảnh thư mục mới. Được gọi từ backend qua window.setDirectoryContext. */
export function setBoneContext(dirPath) {
    if (!dirPath) return;

    els.boneDirText.textContent = dirPath;
    show(els.boneContextBar);
    show(els.mouthBone);

    native.setContextDir(dirPath);

    if (!isAiWoken()) wake();
    happy();
    showBubble();

    els.statusLabel.textContent = "Đã nhận Cục Xương bối cảnh!";
    showMessage(`
    <div class="msg msg-ai">
      <div class="msg-body">
        🍖 <b>Gâu gâu! Em đã ngậm Cục Xương bối cảnh:</b><br>
        <code>${escapeHtml(dirPath)}</code><br><br>
        ${escapeHtml(getAddressing())} muốn em làm gì trong thư mục này ạ? (Ví dụ: <i>"thống kê số lượng tập tin nix"</i>, <i>"tìm file cấu hình"</i>, <i>"chạy lệnh git status"</i>...)
      </div>
    </div>
  `);
    setPlaceholder(`Hỏi về thư mục ${dirPath}...`);
    focusInput();
}

/** Gỡ bỏ bối cảnh thư mục hiện tại. */
export function clearBoneContext() {
    hide(els.boneContextBar);
    hide(els.mouthBone);

    native.clearContextDir();

    setPlaceholder(DEFAULT_PLACEHOLDER);
    els.statusLabel.textContent = "Đã gỡ bối cảnh thư mục";
}

export function initBoneContext() {
    els.btnClearBone.addEventListener("click", (e) => {
        e.stopPropagation();
        clearBoneContext();
    });

    // Cho phép backend (CGo/IPC) gọi trực tiếp từ JS.
    window.setDirectoryContext = setBoneContext;
}
