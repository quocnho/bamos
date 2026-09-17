// ============================================================================
// core/wails-bridge.js — Cầu nối IPC chuẩn Wails v3
// ----------------------------------------------------------------------------
// Chuẩn hóa tương tác giữa Frontend UI và Golang Backend theo mô hình Wails v3:
//   1. RPC Async Calls:  wails.Call(method, ...args) -> Promise
//   2. Event Bus:        wails.Events.On(name, cb) / wails.Events.Emit(name, data)
// ============================================================================

import { bus } from "./bus.js";

/** Truy cập runtime wails do Go WebKit tiêm vào window hoặc shim dự phòng. */
function getWailsRuntime() {
    if (typeof window !== "undefined" && window.wails) {
        return window.wails;
    }
    return null;
}

export const wailsBridge = {
    /**
     * Gọi một RPC method phía Go backend, trả về Promise kết quả.
     * @param {string} method Tên hàm (vd: 'getSettings', 'saveSettings', 'ask')
     * @param  {...any} args Tham số truyền vào
     * @returns {Promise<any>}
     */
    async call(method, ...args) {
        const rt = getWailsRuntime();
        if (rt && typeof rt.Call === "function") {
            try {
                return await rt.Call(method, ...args);
            } catch (err) {
                console.warn(`[WailsBridge] Lỗi RPC Call "${method}":`, err);
                throw err;
            }
        }

        // Dự phòng: nếu chạy trên WebView với window.assistantNative
        if (typeof window !== "undefined" && window.assistantNative) {
            const fn = window.assistantNative[method];
            if (typeof fn === "function") {
                try {
                    const result = fn(...args);
                    return Promise.resolve(result);
                } catch (err) {
                    return Promise.reject(err);
                }
            }
        }

        console.info(`[WailsBridge Mock] ${method}(`, ...args, `)`);
        return Promise.resolve(null);
    },

    /**
     * Đăng ký lắng nghe sự kiện từ backend hoặc giữa các module frontend.
     */
    on(eventName, callback) {
        const rt = getWailsRuntime();
        if (rt && rt.Events && typeof rt.Events.On === "function") {
            return rt.Events.On(eventName, callback);
        }
        return bus.on(eventName, callback);
    },

    /**
     * Phát sự kiện.
     */
    emit(eventName, data) {
        const rt = getWailsRuntime();
        if (rt && rt.Events && typeof rt.Events.Emit === "function") {
            rt.Events.Emit(eventName, data);
        }
        bus.emit(eventName, data);
    },
};
