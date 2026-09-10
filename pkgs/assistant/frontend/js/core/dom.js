// ============================================================================
// core/dom.js — Truy cập DOM tập trung
// ----------------------------------------------------------------------------
// Mọi element của giao diện được cache tại một chỗ duy nhất (single source of
// truth). Nhờ vậy các module nghiệp vụ không phải gọi getElementById rải rác,
// tránh lỗi chính tả id và dễ rà soát khi HTML thay đổi.
//
// Lưu ý: file main.js được nạp dạng `type="module"` nên mặc định bị hoãn
// (deferred); tới lúc thực thi thì toàn bộ DOM đã được parse xong.
// ============================================================================

/** Lấy element theo id. */
export const $ = (id) => document.getElementById(id);

/** Lấy danh sách element theo selector (trả về mảng thật). */
export const $$ = (selector, root = document) =>
    Array.from(root.querySelectorAll(selector));

// ---------------------------------------------------------------------------
// Cache element dùng chung
// ---------------------------------------------------------------------------
export const els = {
    // Chú cún + bong bóng chat
    petWrapper: $("pet-wrapper"),
    speechBubble: $("speech-bubble"),
    bubbleHeader: document.querySelector(".bubble-header"),
    chatStream: $("chat-stream"),
    chatInput: $("chat-input"),
    btnSend: $("btn-send"),
    btnRagToggle: $("btn-rag-toggle"),
    ragBadge: $("rag-badge"),
    statusLabel: $("status-label"),
    heartBurst: $("heart-burst"),

    // Thanh điều khiển cửa sổ
    btnMinimize: $("btn-minimize"),
    btnClose: $("btn-close"),
    btnAlwaysOnTop: $("btn-always-on-top"),
    btnSleep: $("btn-sleep-cún"),
    btnEyeleoToggle: $("btn-eyeleo-toggle"),

    // Cục Xương — bối cảnh thư mục
    boneContextBar: $("bone-context-bar"),
    boneDirText: $("bone-dir-text"),
    btnClearBone: $("btn-clear-bone"),
    mouthBone: $("mouth-bone"),

    // Đính kèm tệp/hình ảnh
    btnStopStream: $("btn-stop-stream"),
    btnAttach: $("btn-attach"),
    fileUploadInput: $("file-upload-input"),
    attachedPreviewBar: $("attached-preview-bar"),
    attachedFilename: $("attached-filename"),
    attachedIcon: $("attached-icon"),
    btnRemoveAttachment: $("btn-remove-attachment"),

    // EyeLeo — thông báo trước giờ nghỉ
    eyeleoPrebreakToast: $("eyeleo-prebreak-toast"),
    prebreakSeconds: $("prebreak-seconds"),
    btnPrebreakDismiss: $("btn-prebreak-dismiss"),

    // EyeLeo — nghỉ ngắn
    eyeleoShortbreakBubble: $("eyeleo-shortbreak-bubble"),
    shortbreakExerciseName: $("shortbreak-exercise-name"),
    shortbreakIcon: $("shortbreak-icon"),
    shortbreakInstruction: $("shortbreak-instruction"),
    shortbreakProgress: $("shortbreak-progress"),
    shortbreakCountdown: $("shortbreak-countdown"),
    btnShortbreakSkip: $("btn-shortbreak-skip"),

    // EyeLeo — nghỉ dài
    eyeleoLongbreakOverlay: $("eyeleo-longbreak-overlay"),
    longbreakClock: $("longbreak-clock"),
    strictModeIndicator: $("strict-mode-indicator"),
    btnLongbreakPostpone: $("btn-longbreak-postpone"),
    btnLongbreakSkip: $("btn-longbreak-skip"),

    // EyeLeo — modal cài đặt
    eyeleoSettingsModal: $("eyeleo-settings-modal"),
    btnCloseEyeleoSettings: $("btn-close-eyeleo-settings"),
    btnSaveSettings: $("btn-save-settings"),
    setEyeleoActive: $("set-eyeleo-active"),
    setShortInterval: $("set-short-interval"),
    setShortDuration: $("set-short-duration"),
    setLongInterval: $("set-long-interval"),
    setLongDuration: $("set-long-duration"),
    setStrictMode: $("set-strict-mode"),
    setPrebreakNotify: $("set-prebreak-notify"),
    setAutoIdle: $("set-auto-idle"),
    setSoundEnabled: $("set-sound-enabled"),
};

// ---------------------------------------------------------------------------
// Tiện ích bật/tắt lớp `hidden`
// ---------------------------------------------------------------------------
export function show(node) {
    if (node) node.classList.remove("hidden");
}

export function hide(node) {
    if (node) node.classList.add("hidden");
}

export function isHidden(node) {
    return !node || node.classList.contains("hidden");
}
