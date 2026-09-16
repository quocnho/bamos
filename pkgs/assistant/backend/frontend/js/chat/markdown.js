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
        (_m, lang, code) => {
            const langLabel = lang ? `<span class="code-lang">${escapeHtml(lang)}</span>` : "";
            return `
            <div class="code-block-wrapper">
                <div class="code-header">
                    ${langLabel}
                    <button class="code-copy-btn" title="Sao chép mã nguồn" type="button">📋 Sao chép</button>
                </div>
                <pre><code>${escapeHtml(code.trim())}</code></pre>
            </div>`;
        },
    );

    // 4. Bảng Markdown: | Tiêu đề 1 | Tiêu đề 2 | ...
    processed = renderMarkdownTables(processed);

    // 5. Inline code `code`
    processed = processed.replace(
        /`([^`\n]+)`/g,
        (_m, code) => `<code>${escapeHtml(code)}</code>`,
    );

    // 6. Tiêu đề h1/h2/h3/h4
    processed = processed.replace(/^#### (.*$)/gim, "<h4>$1</h4>");
    processed = processed.replace(/^### (.*$)/gim, "<h3>$1</h3>");
    processed = processed.replace(/^## (.*$)/gim, "<h2>$1</h2>");
    processed = processed.replace(/^# (.*$)/gim, "<h1>$1</h1>");

    // 7. In đậm **text** hoặc __text__
    processed = processed.replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>");
    processed = processed.replace(/__(.*?)__/g, "<strong>$1</strong>");

    // 8. In nghiêng *text* hoặc _text_
    processed = processed.replace(/\*([^*\n]+)\*/g, "<em>$1</em>");
    processed = processed.replace(/_([^_\n]+)_/g, "<em>$1</em>");

    // 9. Trích dẫn > text
    processed = processed.replace(/^> (.*$)/gim, "<blockquote>$1</blockquote>");

    // 10. Danh sách gạch đầu dòng (- hoặc *)
    processed = processed.replace(
        /^\s*[-*]\s+(.*$)/gim,
        "<ul><li>$1</li></ul>",
    );
    processed = processed.replace(/<\/ul>\s*<ul>/g, ""); // Gộp các <ul> liền kề

    // 11. Danh sách đánh số thứ tự (1. 2. 3.)
    processed = processed.replace(
        /^\s*(\d+)\.\s+(.*$)/gim,
        "<ol><li>$2</li></ol>",
    );
    processed = processed.replace(/<\/ol>\s*<ol>/g, ""); // Gộp các <ol> liền kề

    // 12. Liên kết tự động http/https
    processed = processed.replace(
        /(https?:\/\/[^\s<]+)/g,
        '<a href="$1" target="_blank" rel="noopener noreferrer">$1</a>',
    );

    // 13. Ngắt dòng thông minh (trừ trường hợp nằm trong thẻ block)
    processed = processed.replace(/\n/g, "<br>");
    processed = processed.replace(/<\/div><br>/g, "</div>");
    processed = processed.replace(/<\/pre><br>/g, "</pre>");
    processed = processed.replace(/<\/table><br>/g, "</table>");
    processed = processed.replace(/<\/ul><br>/g, "</ul>");
    processed = processed.replace(/<\/ol><br>/g, "</ol>");
    processed = processed.replace(/<\/h[1-4]><br>/g, (m) => m.slice(0, -4));

    return processed;
}

/** Chuyển đổi cú pháp bảng Markdown thành bảng HTML cuộn được trong khung chat 480px. */
function renderMarkdownTables(text) {
    const tableRegex = /((?:\|[^\n]+\|\r?\n)+)/g;
    return text.replace(tableRegex, (match) => {
        const lines = match.trim().split("\n").map(l => l.trim()).filter(Boolean);
        if (lines.length < 2) return match;

        // Dòng phân cách |---|---|
        if (!lines[1].includes("-")) return match;

        const parseRow = (rowStr) => {
            return rowStr
                .replace(/^\|/, "")
                .replace(/\|$/, "")
                .split("|")
                .map(c => c.trim());
        };

        const headers = parseRow(lines[0]);
        const bodyLines = lines.slice(2);

        let tableHtml = '<div class="table-container"><table class="markdown-table"><thead><tr>';
        headers.forEach(h => {
            tableHtml += `<th>${escapeHtml(h)}</th>`;
        });
        tableHtml += '</tr></thead><tbody>';

        bodyLines.forEach(bRow => {
            const cells = parseRow(bRow);
            tableHtml += '<tr>';
            cells.forEach(c => {
                tableHtml += `<td>${escapeHtml(c)}</td>`;
            });
            tableHtml += '</tr>';
        });

        tableHtml += '</tbody></table></div>';
        return tableHtml;
    });
}
