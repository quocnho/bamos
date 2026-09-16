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
export const els = {};

export function initDOM() {
    // Chú cún + bong bóng chat
    els.petWrapper = $("pet-wrapper");
    els.speechBubble = $("speech-bubble");
    // PHẢI chỉ định trong #speech-bubble: trang có nhiều .bubble-header (bong bóng
    // nghỉ ngắn EyeLeo đứng trước trong DOM) nên querySelector đơn thuần sẽ bắt nhầm.
    els.bubbleHeader = document.querySelector("#speech-bubble .bubble-header");
    els.chatStream = $("chat-stream");
    els.chatInput = $("chat-input");
    els.btnSend = $("btn-send");
    els.statusLabel = $("status-label");
    els.heartBurst = $("heart-burst");

    // Thanh điều khiển cửa sổ
    els.btnMinimize = $("btn-minimize");
    els.btnClose = $("btn-close");
    els.btnAlwaysOnTop = $("btn-always-on-top");
    els.btnStopStream = $("btn-stop-stream");

    // Phiên hội thoại
    els.btnNewChat = $("btn-new-chat");
    els.btnRecentChat = $("btn-recent-chat");
    els.recentSessionsModal = $("recent-sessions-modal");
    els.recentList = $("recent-sessions-list");
    els.btnCloseRecent = $("btn-close-recent");

    // Menu Thiết lập (nút ⚙ ở header)
    els.btnSettings = $("btn-settings");
    els.settingsMenu = $("settings-menu");

    // Giới thiệu BamAI
    els.aboutModal = $("about-modal");
    els.btnCloseAbout = $("btn-close-about");
    els.btnAboutClose = $("btn-about-close");

    // Chip gợi ý + tooltip
    els.smartChips = $("smart-chips");
    els.chipTooltip = $("chip-tooltip");

    // Cục Xương — bối cảnh thư mục
    els.boneContextBar = $("bone-context-bar");
    els.boneDirText = $("bone-dir-text");
    els.btnClearBone = $("btn-clear-bone");
    els.mouthBone = $("mouth-bone");

    // Đính kèm tệp/hình ảnh
    els.btnAttach = $("btn-attach");
    els.fileUploadInput = $("file-upload-input");
    els.attachedPreviewBar = $("attached-preview-bar");
    els.attachedFilename = $("attached-filename");
    els.attachedIcon = $("attached-icon");
    els.btnRemoveAttachment = $("btn-remove-attachment");

    // EyeLeo — thông báo trước giờ nghỉ
    els.eyeleoPrebreakToast = $("eyeleo-prebreak-toast");
    els.prebreakSeconds = $("prebreak-seconds");
    els.btnPrebreakDismiss = $("btn-prebreak-dismiss");

    // EyeLeo — nghỉ ngắn
    els.eyeleoShortbreakBubble = $("eyeleo-shortbreak-bubble");
    els.shortbreakExerciseName = $("shortbreak-exercise-name");
    els.shortbreakIcon = $("shortbreak-icon");
    els.shortbreakInstruction = $("shortbreak-instruction");
    els.shortbreakProgress = $("shortbreak-progress");
    els.shortbreakCountdown = $("shortbreak-countdown");
    els.btnShortbreakSkip = $("btn-shortbreak-skip");

    // EyeLeo — nghỉ dài
    els.eyeleoLongbreakOverlay = $("eyeleo-longbreak-overlay");
    els.longbreakClock = $("longbreak-clock");
    els.strictModeIndicator = $("strict-mode-indicator");
    els.btnLongbreakPostpone = $("btn-longbreak-postpone");
    els.btnLongbreakSkip = $("btn-longbreak-skip");

    // EyeLeo — modal cài đặt
    els.eyeleoSettingsModal = $("eyeleo-settings-modal");
    els.btnCloseEyeleoSettings = $("btn-close-eyeleo-settings");
    els.btnSaveSettings = $("btn-save-settings");
    els.setEyeleoActive = $("set-eyeleo-active");
    els.setShortInterval = $("set-short-interval");
    els.setShortDuration = $("set-short-duration");
    els.setLongInterval = $("set-long-interval");
    els.setLongDuration = $("set-long-duration");
    els.setStrictMode = $("set-strict-mode");
    els.setPrebreakNotify = $("set-prebreak-notify");
    els.setAutoIdle = $("set-auto-idle");
    els.setSoundEnabled = $("set-sound-enabled");

    // Thiết lập RAG
    els.ragSettingsModal = $("rag-settings-modal");
    els.btnCloseRagSettings = $("btn-close-rag-settings");
    els.setRagEnabled = $("set-rag-enabled");
    els.setRagTopK = $("set-rag-topk");
    els.setRagTopKValue = $("set-rag-topk-value");
    els.setRagAlpha = $("set-rag-alpha");
    els.setRagAlphaValue = $("set-rag-alpha-value");
    els.ragDropzone = $("rag-dropzone");
    els.ragFileInput = $("rag-file-input");
    els.ragPendingList = $("rag-pending-list");
    els.btnRagIndex = $("btn-rag-index");
    els.btnRagClear = $("btn-rag-clear");
    els.ragStatus = $("rag-status");
    els.ragCountBadge = $("rag-count-badge");
    els.btnRefreshRagDocs = $("btn-refresh-rag-docs");
    els.ragDocsContainer = $("rag-docs-container");
    els.btnSaveRagSettings = $("btn-save-rag-settings");

    // Thiết lập LLM
    els.llmSettingsModal = $("llm-settings-modal");
    els.btnCloseLlmSettings = $("btn-close-llm-settings");
    els.setLlmProvider = $("set-llm-provider");
    els.llmKeyDeepseek = $("llm-key-deepseek");
    els.llmKeyOpenai = $("llm-key-openai");
    els.llmKeyGemini = $("llm-key-gemini");
    els.setDeepseekKey = $("set-deepseek-key");
    els.setOpenaiKey = $("set-openai-key");
    els.setGeminiKey = $("set-gemini-key");
    els.llmLocalSection = $("llm-local-section");
    els.setModelDir = $("set-model-dir");
    els.btnLlmRefreshModels = $("btn-llm-refresh-models");
    els.llmModelList = $("llm-model-list");
    els.setModelUrl = $("set-model-url");
    els.btnLlmDownload = $("btn-llm-download");
    els.llmDownloadProgress = $("llm-download-progress");
    els.setTemperature = $("set-temperature");
    els.setTempValue = $("set-temp-value");
    els.setContextSize = $("set-context-size");
    els.setGpuLayers = $("set-gpu-layers");
    els.llmStatus = $("llm-status");
    els.btnLlmTest = $("btn-llm-test");
    els.btnLlmRestart = $("btn-llm-restart");
    els.btnSaveLlmSettings = $("btn-save-llm-settings");

    // Giám sát hệ thống
    els.systemInspectModal = $("system-inspect-modal");
    els.btnCloseSystemInspect = $("btn-close-system-inspect");
    els.btnRunSystemInspect = $("btn-run-system-inspect");
    els.systemInspectStatus = $("system-inspect-status");
    els.systemIssuesList = $("system-issues-list");
    els.systemIdleAppsList = $("system-idle-apps-list");

    // WakaTracker
    els.wakaModal = $("waka-modal");
    els.btnCloseWaka = $("btn-close-waka");
    els.wakaTodayHours = $("waka-today-hours");
    els.waka7DaysHours = $("waka-7days-hours");
    els.wakaCategoriesList = $("waka-categories-list");
    els.wakaNewReminderTitle = $("waka-new-reminder-title");
    els.wakaNewReminderTime = $("waka-new-reminder-time");
    els.btnWakaAddReminder = $("btn-waka-add-reminder");
    els.wakaRemindersList = $("waka-reminders-list");

    // Hồ sơ người dùng
    els.profileModal = $("profile-modal");
    els.btnCloseProfile = $("btn-close-profile");
    els.tabProfileInfo = $("tab-profile-info");
    els.tabProfileQuiz = $("tab-profile-quiz");
    els.tabProfileRoadmap = $("tab-profile-roadmap");
    els.panelProfileInfo = $("panel-profile-info");
    els.panelProfileQuiz = $("panel-profile-quiz");
    els.panelProfileRoadmap = $("panel-profile-roadmap");
    els.profFullname = $("prof-fullname");
    els.profAge = $("prof-age");
    els.profPhone = $("prof-phone");
    els.profEmail = $("prof-email");
    els.profAddressing = $("prof-addressing");
    els.profAddressingCustom = $("prof-addressing-custom");
    els.profThemeColor = $("prof-theme-color");
    els.profDomainsContainer = $("prof-domains-container");
    els.profDomainsCounter = $("prof-domains-counter");
    els.btnSaveProfile = $("btn-save-profile");
    els.profileStatus = $("profile-status");
    els.quizContainer = $("quiz-container");
    els.btnSubmitQuiz = $("btn-submit-quiz");
    els.profCurrentLevel = $("prof-current-level");
    els.roadmapStepsList = $("roadmap-steps-list");

    // Nhúng Web Widget & Whitelist Studio
    els.embedSettingsModal = $("embed-settings-modal");
    els.btnCloseEmbedSettings = $("btn-close-embed-settings");
    els.tabEmbedStudio = $("tab-embed-studio");
    els.tabEmbedWhitelist = $("tab-embed-whitelist");
    els.panelEmbedStudio = $("panel-embed-studio");
    els.panelEmbedWhitelist = $("panel-embed-whitelist");
    els.cfgEmbedPort = $("cfg-embed-port");
    els.btnScanNetwork = $("btn-scan-network");
    els.cfgEmbedHost = $("cfg-embed-host");
    els.networkAddressesChips = $("network-addresses-chips");
    els.networkScanStatus = $("network-scan-status");
    els.cfgEmbedPosition = $("cfg-embed-position");
    els.cfgEmbedColor = $("cfg-embed-color");
    els.cfgEmbedTitle = $("cfg-embed-title");
    els.cfgEmbedRAG = $("cfg-embed-rag");
    els.btnSaveEmbedConfig = $("btn-save-embed-config");
    els.embedSaveStatus = $("embed-save-status");
    els.miniPreviewTitle = $("mini-preview-title");
    els.miniChatHeader = $("mini-chat-header");
    els.miniFloatingBtn = $("mini-floating-btn");
    els.miniPreviewStage = $("mini-preview-stage");
    els.generatedEmbedCode = $("generated-embed-code");
    els.btnCopyEmbedCode = $("btn-copy-embed-code");
    els.copyCodeText = $("copy-code-text");
    els.whitelistSearchInput = $("whitelist-search-input");
    els.whitelistSortSelect = $("whitelist-sort-select");
    els.btnOpenAddDomain = $("btn-open-add-domain");
    els.cfgEnforceWhitelist = $("cfg-enforce-whitelist");
    els.whitelistTableBody = $("whitelist-table-body");
    els.whitelistEmptyState = $("whitelist-empty-state");
    els.domainEditorModal = $("domain-editor-modal");
    els.domainEditorTitle = $("domain-editor-title");
    els.btnCloseDomainEditor = $("btn-close-domain-editor");
    els.editDomainId = $("edit-domain-id");
    els.editDomainInput = $("edit-domain-input");
    els.editDomainNote = $("edit-domain-note");
    els.editDomainEnabled = $("edit-domain-enabled");
    els.btnSaveDomainItem = $("btn-save-domain-item");

    // Thiết lập Giao diện & Thú cưng (Appearance Settings)
    els.appearanceSettingsModal = $("appearance-settings-modal");
    els.btnCloseAppearanceSettings = $("btn-close-appearance-settings");
    els.btnSaveAppearance = $("btn-save-appearance");
    els.appearanceSaveStatus = $("appearance-save-status");
}

initDOM();

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
