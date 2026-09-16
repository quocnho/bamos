// ============================================================================
// core/bus.js — Event bus siêu nhỏ
// ----------------------------------------------------------------------------
// Cho phép các module giao tiếp mà không cần import vòng (circular import).
// Ví dụ: chat.js phát sự kiện "session:ensure-awake", pet.js lắng nghe và
// đánh thức chú cún — hai module không cần biết tới nhau.
// ============================================================================

const listeners = new Map();

/** Đăng ký một handler cho sự kiện; trả về hàm huỷ đăng ký. */
export function on(event, handler) {
    const set = listeners.get(event) || new Set();
    set.add(handler);
    listeners.set(event, set);
    return () => off(event, handler);
}

/** Huỷ đăng ký. */
export function off(event, handler) {
    const set = listeners.get(event);
    if (set) set.delete(handler);
}

/** Phát sự kiện tới toàn bộ handler đang lắng nghe. */
export function emit(event, payload) {
    const set = listeners.get(event);
    if (!set) return;
    // Sao chép danh sách để handler có thể tự huỷ đăng ký an toàn.
    for (const handler of [...set]) {
        try {
            handler(payload);
        } catch (err) {
            console.warn(`[BamAI bus] Lỗi khi xử lý sự kiện "${event}":`, err);
        }
    }
}

export const bus = { on, off, emit };
