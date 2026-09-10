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
    // Cửa sổ
    dragWindow: () => call("dragWindow"),
    closeApp: () => call("closeApp"),
    setAlwaysOnTop: (enabled) => call("setAlwaysOnTop", enabled),
    activateAndRaise: () => call("activateAndRaise"),
    setFullscreen: (enabled) => call("setFullscreen", enabled),

    // AI
    wakeAI: () => call("wakeAI"),
    evaluateSleepOrStop: () => call("evaluateSleepOrStop"),
    stopGeneration: () => call("stopGeneration"),
    getIdleTime: () => call("getIdleTime"),
    ask: (question, useRag) => call("ask", question, useRag),

    // Bối cảnh thư mục (Cục Xương)
    setContextDir: (dir) => call("setContextDir", dir),
    clearContextDir: () => call("clearContextDir"),

    // Bảng thiết lập
    getSettings: () => call("getSettings"),
    saveSettings: (settings) => call("saveSettings", settings),
    listModels: () => call("listModels"),
    downloadModel: (url, name) => call("downloadModel", url, name),
    setActiveModel: (path) => call("setActiveModel", path),
    testLLM: () => call("testLLM"),
    restartAI: () => call("restartAI"),

    // Tri thức RAG
    ragAddDocuments: (documents) => call("ragAddDocuments", documents),
    ragStats: () => call("ragStats"),
    ragClear: () => call("ragClear"),
};
