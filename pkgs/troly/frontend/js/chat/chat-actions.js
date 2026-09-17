// ============================================================================
// chat/chat-actions.js — Xử lý các sự kiện click, sao chép mã/nội dung tin nhắn
// ============================================================================

import { copyText } from "../core/clipboard.js";
import { stripHtml } from "../core/utils.js";
import { getCurrentSession } from "./sessions.js";

export function flashCopy(button, ok) {
    button.classList.toggle("copied", ok);
    button.textContent = ok ? "✅" : "⚠️";
    setTimeout(() => {
        button.classList.remove("copied");
        button.textContent = "📋";
    }, 1200);
}

export function handleStreamClick(e) {
    // 1. Sao chép riêng khối code
    const codeBtn = e.target && e.target.closest ? e.target.closest(".code-copy-btn") : null;
    if (codeBtn) {
        const wrapper = codeBtn.closest(".code-block-wrapper");
        const codeEl = wrapper ? wrapper.querySelector("pre code") : null;
        if (codeEl) {
            copyText(codeEl.textContent || "").then((ok) => {
                codeBtn.textContent = ok ? "✅ Đã chép" : "⚠️ Lỗi";
                codeBtn.classList.add("copied");
                setTimeout(() => {
                    codeBtn.textContent = "📋 Sao chép";
                    codeBtn.classList.remove("copied");
                }, 1500);
            });
        }
        return;
    }

    // 2. Sao chép toàn bộ tin nhắn
    const button = e.target && e.target.closest ? e.target.closest(".msg-copy") : null;
    if (!button) return;

    const msg = button.closest(".msg");
    const index = msg && msg.dataset ? Number(msg.dataset.turn) : NaN;
    const turn = Number.isInteger(index)
        ? getCurrentSession().transcript[index]
        : null;
    const text = turn ? stripHtml(turn.text) : "";
    if (!text) return;

    copyText(text).then((ok) => flashCopy(button, ok));
}
