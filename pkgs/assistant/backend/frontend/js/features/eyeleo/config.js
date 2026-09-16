// ============================================================================
// features/eyeleo/config.js — Cấu hình & lưu trữ EyeLeo
// ----------------------------------------------------------------------------
// Cài đặt mặc định theo chuẩn công thái học thị giác (20-20-20) và được lưu
// vào localStorage để giữ nguyên giữa các lần mở ứng dụng.
// ============================================================================

// Khoá localStorage lưu cấu hình EyeLeo.
export const STORAGE_KEY = "eyeleo_config";

export const DEFAULT_CONFIG = {
    enabled: true,
    shortIntervalMinutes: 10,
    shortDurationSeconds: 8,
    longIntervalMinutes: 50,
    longDurationSeconds: 300, // 5 phút
    strictMode: false,
    prebreakNotify: true,
    autoIdle: true,
    soundEnabled: true,
    idleThresholdMs: 3 * 60 * 1000, // 3 phút
};

/** Đọc cấu hình đã lưu, hợp nhất với giá trị mặc định. */
export function loadConfig() {
    try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) return Object.assign({}, DEFAULT_CONFIG, JSON.parse(saved));
    } catch (err) {
        console.warn("[EyeLeo] Lỗi đọc localStorage:", err);
    }
    return { ...DEFAULT_CONFIG };
}

/** Lưu cấu hình xuống localStorage. */
export function saveConfig(config) {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
    } catch (err) {
        console.warn("[EyeLeo] Lỗi lưu localStorage:", err);
    }
}
