// ============================================================================
// chat/chat-render.js — Khởi tạo DOM HTML cho các tin nhắn trong khung chat
// ============================================================================

import { escapeHtml } from "../core/utils.js";
import { getAddressing } from "../core/state.js";
import { renderVisualMarkdown } from "./markdown.js";

export function welcomeBlock() {
    return `
    <div class="welcome-msg">
      🐶 <b>Xin chào ${escapeHtml(getAddressing())}!</b> Em đang ở đây, sẵn sàng hỗ trợ ạ! Hãy nhấp vào ô chat để bắt đầu nhé!
    </div>`;
}

export function userBlock(text, turnIndex) {
    return `
    <div class="msg msg-user" data-turn="${turnIndex}">
      <div class="msg-head">
        <span class="msg-role">🧑 ${escapeHtml(getAddressing())}</span>
        <button class="msg-copy" title="Sao chép câu hỏi">📋</button>
      </div>
      <div class="msg-body">${escapeHtml(text)}</div>
    </div>`;
}

export function aiBlock(raw, turnIndex, { streaming = false } = {}) {
    const body = raw
        ? renderVisualMarkdown(raw)
        : "<i>Em đang tra cứu và xử lý...</i>";
    const id = streaming ? ' id="current-reply"' : "";
    const copy = streaming
        ? ""
        : '<button class="msg-copy" title="Sao chép câu trả lời">📋</button>';
    return `
    <div class="msg msg-ai" data-turn="${turnIndex}">
      <div class="msg-head">
        <span class="msg-role">🐶 BamAI</span>
        ${copy}
      </div>
      <div class="msg-body"${id}>${body}</div>
    </div>`;
}
