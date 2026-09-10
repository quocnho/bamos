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
    statusLabel: $("status-label"),
    heartBurst: $("heart-burst"),

    // Thanh điều khiển cửa sổ
    btnMinimize: $("btn-minimize"),
    btnClose: $("btn-close"),
    btnAlwaysOnTop: $("btn-always-on-top"),
    btnRagSettings: $("btn-rag-settings"),
    btnLlmSettings: $("btn-llm-settings"),
    btnEyeleoToggle: $("btn-eyeleo-toggle"),
    btnStopStream: $("btn-stop-stream"),

    // Chip gợi ý + tooltip
    smartChips: $("smart-chips"),
    chipTooltip: $("chip-tooltip"),

    // Cục Xương — bối cảnh thư mục
    boneContextBar: $("bone-context-bar"),
    boneDirText: $("bone-dir-text"),
    btnClearBone: $("btn-clear-bone"),
    mouthBone: $("mouth-bone"),

    // Đính kèm tệp/hình ảnh
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

    // Bảng thiết lập RAG
    ragSettingsModal: $("rag-settings-modal"),
    btnCloseRagSettings: $("btn-close-rag-settings"),
    setRagEnabled: $("set-rag-enabled"),
    setAddressing: $("set-addressing"),
    setAddressingCustom: $("set-addressing-custom"),
    setRagTopk: $("set-rag-topk"),
    setRagTopkValue: $("set-rag-topk-value"),
    ragCountBadge: $("rag-count-badge"),
    ragDropzone: $("rag-dropzone"),
    ragFileInput: $("rag-file-input"),
    ragPendingList: $("rag-pending-list"),
    btnRagIndex: $("btn-rag-index"),
    btnRagClear: $("btn-rag-clear"),
    ragStatus: $("rag-status"),
    btnSaveRagSettings: $("btn-save-rag-settings"),

    // Bảng thiết lập LLM
    llmSettingsModal: $("llm-settings-modal"),
    btnCloseLlmSettings: $("btn-close-llm-settings"),
    setLlmProvider: $("set-llm-provider"),
    llmKeyDeepseek: $("llm-key-deepseek"),
    llmKeyOpenai: $("llm-key-openai"),
    llmKeyGemini: $("llm-key-gemini"),
    setDeepseekKey: $("set-deepseek-key"),
    setOpenaiKey: $("set-openai-key"),
    setGeminiKey: $("set-gemini-key"),
    llmLocalSection: $("llm-local-section"),
    setModelDir: $("set-model-dir"),
    btnLlmRefreshModels: $("btn-llm-refresh-models"),
    llmModelList: $("llm-model-list"),
    setModelUrl: $("set-model-url"),
    btnLlmDownload: $("btn-llm-download"),
    llmDownloadProgress: $("llm-download-progress"),
    setTemperature: $("set-temperature"),
    setTempValue: $("set-temp-value"),
    setContextSize: $("set-context-size"),
    setGpuLayers: $("set-gpu-layers"),
    llmStatus: $("llm-status"),
    btnLlmTest: $("btn-llm-test"),
    btnLlmRestart: $("btn-llm-restart"),
    btnSaveLlmSettings: $("btn-save-llm-settings"),
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

/** Hiển thị/ẩn phần tử theo giá trị boolean. */
export function toggle(node, visible) {
    if (node) node.classList.toggle("hidden", !visible);
}
