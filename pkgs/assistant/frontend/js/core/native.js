// ============================================================================
// core/native.js — Cầu nối tới Go backend (window.assistantNative)
// ----------------------------------------------------------------------------
// Script shim do gui_linux.go tiêm vào sẽ tạo `window.assistantNative`. Khi
// chạy thử frontend trên trình duyệt thường (không có shim), mọi lời gọi đều
// trở thành no-op an toàn nhờ lớp bọc dưới đây.
// ============================================================================

/** Trả về đối tượng cầu nối native nếu đang chạy trong WebKit, ngược lại null. */
function bridge() {
    return typeof window !== "undefined" ? window.assistantNative : null;
}

function call(method, ...args) {
    const api = bridge();
    if (!api || typeof api[method] !== "function") return false;
    try {
        api[method](...args);
        return true;
    } catch (err) {
        console.warn(`[BamAI native] Lỗi khi gọi "${method}":`, err);
        return false;
    }
}

export const native = {
    dragWindow: () => call("dragWindow"),
    closeApp: () => call("closeApp"),
    setAlwaysOnTop: (enabled) => call("setAlwaysOnTop", enabled),
    wakeAI: () => call("wakeAI"),
    evaluateSleepOrStop: () => call("evaluateSleepOrStop"),
    setContextDir: (dir) => call("setContextDir", dir),
    clearContextDir: () => call("clearContextDir"),
    getIdleTime: () => call("getIdleTime"),
    activateAndRaise: () => call("activateAndRaise"),
    stopGeneration: () => call("stopGeneration"),
    ask: (question, useRag) => call("ask", question, useRag),
};
