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
    // Nhắc nhở nghỉ ngơi: đưa cửa sổ lên cao nhất (ghim tạm trên cùng ~12s).
    raiseNotification: () => call("raiseNotification"),
    setFullscreen: (enabled) => call("setFullscreen", enabled),

    // Kích thước cửa sổ (khít nội dung chat + pet)
    setContentSize: (width, height) => call("setContentSize", width, height),
    setWindowFull: (full) => call("setWindowFull", full),

    // Nhật ký chẩn đoán (hiện ra stdout của tiến trình Go)
    log: (message) => call("log", message),

    // Mở liên kết bằng trình duyệt/ứng dụng mặc định của hệ thống.
    openUrl: (url) => call("openUrl", url),

    // AI
    wakeAI: () => call("wakeAI"),
    ensureServices: () => call("ensureServices"),
    evaluateSleepOrStop: () => call("evaluateSleepOrStop"),
    stopGeneration: () => call("stopGeneration"),
    getIdleTime: () => call("getIdleTime"),
    ask: (question, useRag, history) => call("ask", question, useRag, history),

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

    // Tri thức RAG (FTS5 + sqlite-vec)
    ragAddDocuments: (documents) => call("ragAddDocuments", documents),
    ragStats: () => call("ragStats"),
    ragClear: () => call("ragClear"),
    ragListDocuments: () => call("ragListDocuments"),
    ragDeleteDoc: (src) => call("ragDeleteDoc", src),

    // Giám sát Hệ thống & NixOS Log
    systemInspect: () => call("systemInspect"),

    // WakaTracker & Lịch làm việc/nhắc việc
    wakaStats: () => call("wakaStats"),
    addReminder: (title, dueTime) => call("addReminder", title, dueTime),
    toggleReminder: (id) => call("toggleReminder", id),

    // Hồ sơ người dùng & Onboarding Quiz
    getProfile: () => call("getProfile"),
    updateProfile: (profile) => call("updateProfile", profile),
    getQuiz: () => call("getQuiz"),
    submitQuiz: (answers) => call("submitQuiz", answers),
};
