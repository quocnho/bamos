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
    petHeadInputBar: $("pet-head-input-bar"),
    headChatInput: $("head-chat-input"),
    headBtnRecent: $("head-btn-recent"),
    headBtnAttach: $("head-btn-attach"),
    headBtnSend: $("head-btn-send"),
    petChestSettingsBtn: $("pet-chest-settings-btn"),
    speechBubble: $("speech-bubble"),
    // PHẢI chỉ định trong #speech-bubble: trang có nhiều .bubble-header (bong bóng
    // nghỉ ngắn EyeLeo đứng trước trong DOM) nên querySelector đơn thuần sẽ bắt nhầm.
    bubbleHeader: document.querySelector("#speech-bubble .bubble-header"),
    chatStream: $("chat-stream"),
    chatInput: $("chat-input"),
    btnSend: $("btn-send"),
    statusLabel: $("status-label"),
    heartBurst: $("heart-burst"),

    // Thanh điều khiển cửa sổ
    btnMinimize: $("btn-minimize"),
    btnClose: $("btn-close"),
    btnAlwaysOnTop: $("btn-always-on-top"),
    btnStopStream: $("btn-stop-stream"),

    // Phiên hội thoại
    btnNewChat: $("btn-new-chat"),
    btnRecentChat: $("btn-recent-chat"),
    recentSessionsModal: $("recent-sessions-modal"),
    recentList: $("recent-sessions-list"),
    btnCloseRecent: $("btn-close-recent"),

    // Menu Thiết lập (nút ⚙ ở header)
    btnSettings: $("btn-settings"),
    settingsMenu: $("settings-menu"),

    // Giới thiệu BamAI
    aboutModal: $("about-modal"),
    btnCloseAbout: $("btn-close-about"),
    btnAboutClose: $("btn-about-close"),

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
    setRagAlpha: $("set-rag-alpha"),
    setRagAlphaValue: $("set-rag-alpha-value"),
    btnRefreshRagDocs: $("btn-refresh-rag-docs"),
    ragDocsContainer: $("rag-docs-container"),

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

    // Giám sát Hệ thống & NixOS
    systemInspectModal: $("system-inspect-modal"),
    btnCloseSystemInspect: $("btn-close-system-inspect"),
    btnRunSystemInspect: $("btn-run-system-inspect"),
    systemInspectStatus: $("system-inspect-status"),
    systemIssuesList: $("system-issues-list"),
    systemIdleAppsList: $("system-idle-apps-list"),

    // WakaTracker
    wakaModal: $("waka-modal"),
    btnCloseWaka: $("btn-close-waka"),
    wakaTodayHours: $("waka-today-hours"),
    waka7daysHours: $("waka-7days-hours"),
    wakaCategoriesList: $("waka-categories-list"),
    wakaNewReminderTitle: $("waka-new-reminder-title"),
    wakaNewReminderTime: $("waka-new-reminder-time"),
    btnWakaAddReminder: $("btn-waka-add-reminder"),
    wakaRemindersList: $("waka-reminders-list"),

    // Hồ sơ người dùng & Onboarding Quiz
    profileModal: $("profile-modal"),
    btnCloseProfile: $("btn-close-profile"),
    tabProfileInfo: $("tab-profile-info"),
    tabProfileQuiz: $("tab-profile-quiz"),
    tabProfileRoadmap: $("tab-profile-roadmap"),
    panelProfileInfo: $("panel-profile-info"),
    panelProfileQuiz: $("panel-profile-quiz"),
    panelProfileRoadmap: $("panel-profile-roadmap"),
    profFullname: $("prof-fullname"),
    profAge: $("prof-age"),
    profPhone: $("prof-phone"),
    profEmail: $("prof-email"),
    profAddressing: $("prof-addressing"),
    profAddressingCustom: $("prof-addressing-custom"),
    profThemeColor: $("prof-theme-color"),
    profDomainsContainer: $("prof-domains-container"),
    profDomainsCounter: $("prof-domains-counter"),
    btnSaveProfile: $("btn-save-profile"),
    profileStatus: $("profile-status"),
    quizContainer: $("quiz-container"),
    btnSubmitQuiz: $("btn-submit-quiz"),
    profCurrentLevel: $("prof-current-level"),
    roadmapStepsList: $("roadmap-steps-list"),
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
