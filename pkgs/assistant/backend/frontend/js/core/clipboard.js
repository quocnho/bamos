// ============================================================================
// core/clipboard.js — Sao chép văn bản vào clipboard
// ----------------------------------------------------------------------------
// Ưu tiên Clipboard API (hoạt động với http://127.0.0.1 vì là secure context),
// tự động lùi về execCommand cho WebKit cũ hoặc khi bị từ chối quyền.
// ============================================================================

function legacyCopy(value) {
    try {
        const area = document.createElement("textarea");
        area.value = value;
        area.setAttribute("readonly", "");
        area.style.position = "fixed";
        area.style.top = "-2000px";
        area.style.left = "-2000px";
        area.style.userSelect = "text";
        document.body.appendChild(area);
        area.select();
        area.setSelectionRange(0, value.length);
        const ok = document.execCommand("copy");
        document.body.removeChild(area);
        return ok;
    } catch (err) {
        console.warn("[BamAI clipboard] Không sao chép được:", err);
        return false;
    }
}

/**
 * Sao chép văn bản vào clipboard.
 * @param {string} text
 * @returns {Promise<boolean>} true nếu thành công.
 */
export async function copyText(text) {
    const value = text == null ? "" : String(text);
    if (!value) return false;

    try {
        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(value);
            return true;
        }
    } catch (err) {
        // Rơi xuống phương án dự phòng bên dưới.
    }
    return legacyCopy(value);
}
