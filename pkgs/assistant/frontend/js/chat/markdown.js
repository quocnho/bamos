// ============================================================================
// chat/markdown.js — Bộ chuyển đổi Markdown nhẹ sang HTML
// ----------------------------------------------------------------------------
// Không dùng thư viện ngoài. Hỗ trợ các cú pháp mà model thường trả về:
// khối terminal, code block, inline code, tiêu đề, đậm/nghiêng, trích dẫn,
// danh sách, liên kết tự động. Mọi nội dung đều được escapeHtml trước khi
// chèn để chống XSS.
// ============================================================================

import { escapeHtml } from "../core/utils.js";

/** Dựng khung "cửa sổ terminal" mô phỏng để hiển thị lệnh `bam` và kết quả. */
function renderTerminalWindow({ cmd, body, streaming }) {
    const displayCmd = cmd || "bam";
    const title = streaming
        ? `⚡ Đang chạy lệnh: <code>${escapeHtml(displayCmd)}</code>...`
        : `🖥️ BamOS Terminal: <code>${escapeHtml(displayCmd)}</code>`;
    const cursor = streaming
        ? '<span style="animation: fastWagTail 0.8s infinite;">▋</span>'
        : "";
    const bodyContent = streaming ? body : body.trim();

    return `
    <div class="terminal-window">
      <div class="terminal-header">
        <div class="terminal-dots">
          <div class="terminal-dot dot-red"></div>
          <div class="terminal-dot dot-yellow"></div>
          <div class="terminal-dot dot-green"></div>
        </div>
        <div class="terminal-title">${title}</div>
      </div>
      <div class="terminal-body">${escapeHtml(bodyContent)}${cursor}</div>
    </div>
  `;
}

/**
 * Chuyển Markdown thô (đang stream) thành HTML hiển thị.
 * @param {string} text Nội dung Markdown.
 * @returns {string} HTML an toàn.
 */
export function renderVisualMarkdown(text) {
    let processed = text;

    // 1. Khối <terminal cmd="...">...</terminal> đã đóng đầy đủ.
    processed = processed.replace(
        /<terminal(?:\s+cmd="([^"]*)")?>([\s\S]*?)<\/terminal>/g,
        (_m, cmd, body) =>
            renderTerminalWindow({ cmd, body, streaming: false }),
    );

    // 2. Khối <terminal cmd="...">... chưa kịp đóng do đang streaming.
    processed = processed.replace(
        /<terminal(?:\s+cmd="([^"]*)")?>([\s\S]*)$/g,
        (_m, cmd, body) => renderTerminalWindow({ cmd, body, streaming: true }),
    );

    // 3. Code block ```lang ... ```
    processed = processed.replace(
        /```([a-zA-Z0-9_-]*)\n([\s\S]*?)```/g,
        (_m, _lang, code) => {
            return `<pre><code>${escapeHtml(code.trim())}</code></pre>`;
        },
    );

    // 4. Inline code `code`
    processed = processed.replace(
        /`([^`\n]+)`/g,
        (_m, code) => `<code>${escapeHtml(code)}</code>`,
    );

    // 5. Tiêu đề h1/h2/h3
    processed = processed.replace(/^### (.*$)/gim, "<h3>$1</h3>");
    processed = processed.replace(/^## (.*$)/gim, "<h2>$1</h2>");
    processed = processed.replace(/^# (.*$)/gim, "<h1>$1</h1>");

    // 6. In đậm **text** hoặc __text__
    processed = processed.replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>");
    processed = processed.replace(/__(.*?)__/g, "<strong>$1</strong>");

    // 7. In nghiêng *text* hoặc _text_
    processed = processed.replace(/\*([^*\n]+)\*/g, "<em>$1</em>");
    processed = processed.replace(/_([^_\n]+)_/g, "<em>$1</em>");

    // 8. Trích dẫn > text
    processed = processed.replace(/^> (.*$)/gim, "<blockquote>$1</blockquote>");

    // 9. Danh sách - hoặc * (thụt dòng)
    processed = processed.replace(
        /^\s*[-*]\s+(.*$)/gim,
        "<ul><li>$1</li></ul>",
    );
    processed = processed.replace(/<\/ul>\s*<ul>/g, ""); // Gộp các <ul> liền kề

    // 10. Liên kết tự động http/https
    processed = processed.replace(
        /(https?:\/\/[^\s<]+)/g,
        '<a href="$1" target="_blank">$1</a>',
    );

    // 11. Ngắt dòng -> <br>
    processed = processed.replace(/\n/g, "<br>");

    return processed;
}
