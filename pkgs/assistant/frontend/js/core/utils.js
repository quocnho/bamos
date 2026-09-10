// ============================================================================
// core/utils.js — Tiện ích dùng chung (escape HTML, định dạng thời gian)
// ============================================================================

/**
 * Thoát ký tự HTML để chèn văn bản người dùng một cách an toàn.
 * Dùng textContent để trình duyệt tự xử lý mã hoá.
 */
export function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text == null ? "" : String(text);
    return div.innerHTML;
}

/** Định dạng giây thành chuỗi mm:ss (ví dụ 300 -> "05:00"). */
export function formatClock(totalSeconds) {
    const safe = Math.max(0, Math.floor(totalSeconds));
    const minutes = Math.floor(safe / 60);
    const seconds = safe % 60;
    return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}
