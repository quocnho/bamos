// ============================================================================
// main.js — Điểm khởi động (entry point) của giao diện BamAI
// ----------------------------------------------------------------------------
// Chỉ làm hai việc: khởi tạo các module và nối callback từ Go backend.
// Toàn bộ nghiệp vụ nằm trong các module con:
//
//   core/       dom, state, bus, native, utils, audio, clipboard, tooltip
//   chat/       chat (hội thoại + sao chép), markdown, attachments,
//               sessions (lưu/mở phiên), session-ui (nút ＋ / 🕘)
//   pet/        pet (vòng đời), drag (di chuyển + double-click), dragdrop
//   features/   bone (bối cảnh thư mục), suggestions (chip tần suất),
//               eyeleo (bảo vệ mắt), settings/{rag-settings, llm-settings,
//               panels, menu}
// ============================================================================

import { setPetState, setAddressing } from "./core/state.js";
import { els } from "./core/dom.js";
import { native } from "./core/native.js";
import { initWindowFit } from "./core/window-fit.js";
import { initPet, scheduleStartupSleep, syncAlwaysOnTop } from "./pet/pet.js";
import { initDrag } from "./pet/drag.js";
import { initFileDrop } from "./pet/dragdrop.js";
import {
    initChat,
    renderTranscript,
    handleWaking,
    handleReady,
    handleChunk,
    handleDone,
    handleError,
} from "./chat/chat.js";
import { initSessionUi } from "./chat/session-ui.js";
import { restoreLatestSession } from "./chat/sessions.js";
import { initBoneContext } from "./features/bone.js";
import { initSuggestions } from "./features/suggestions.js";
import { initEyeLeo } from "./features/eyeleo/controller.js";
import {
    initRagSettings,
    handleSettingsLoaded as ragSettingsLoaded,
    handleSettingsSaved as ragSettingsSaved,
    handleRagStats,
    handleRagIndexProgress,
    handleRagIndexed,
    handleRagCleared,
} from "./features/settings/rag-settings.js";
import {
    initLlmSettings,
    handleSettingsLoaded as llmSettingsLoaded,
    handleSettingsSaved as llmSettingsSaved,
    handleModelsListed,
    handleModelDownloadProgress,
    handleModelDownloaded,
    handleModelDownloadError,
    handleActiveModelSet,
    handleLLMTestResult,
    handleAIRestarted,
} from "./features/settings/llm-settings.js";

import {
    initSettingsPanels,
    openSettingsPanel,
} from "./features/settings/panels.js";
import { initSettingsMenu } from "./features/settings/menu.js";

// Callback do Go backend gọi trực tiếp trên window.
function bindNativeCallbacks() {
    // Hội thoại
    window.onAIWaking = handleWaking;
    window.onAIReady = handleReady;
    window.onAIChunk = handleChunk;
    window.onAIDone = handleDone;
    window.onAIError = handleError;

    // Thiết lập chung
    window.onSettingsLoaded = (result) => {
        if (result && result.settings) {
            setAddressing(result.settings.addressing);
            syncAlwaysOnTop(result.settings.always_on_top);
        }
        ragSettingsLoaded(result);
        llmSettingsLoaded(result);
    };
    window.onSettingsSaved = (result) => {
        ragSettingsSaved(result);
        llmSettingsSaved(result);
    };

    // Thiết lập LLM
    window.onModelsListed = handleModelsListed;
    window.onModelDownloadProgress = handleModelDownloadProgress;
    window.onModelDownloaded = handleModelDownloaded;
    window.onModelDownloadError = handleModelDownloadError;
    window.onActiveModelSet = handleActiveModelSet;
    window.onLLMTestResult = handleLLMTestResult;
    window.onAIRestarted = handleAIRestarted;

    // Tri thức RAG
    window.onRagStats = handleRagStats;
    window.onRagIndexProgress = handleRagIndexProgress;
    window.onRagIndexed = handleRagIndexed;
    window.onRagCleared = handleRagCleared;
}

/**
 * Nếu app được khởi động kèm `#panel=<tên>` (menu GNOME Shell mở khi BamAI chưa
 * chạy), mở bảng thiết lập tương ứng rồi xoá hash để không mở lại khi tải lại.
 */
function openPanelFromHash() {
    const match = /panel=([^&]+)/.exec(window.location.hash || "");
    if (!match) return;

    const panel = decodeURIComponent(match[1]);
    if (window.history && window.history.replaceState) {
        window.history.replaceState(null, "", window.location.pathname);
    }
    // Chờ một nhịp để các bảng thiết lập đã sẵn sàng trước khi mở.
    setTimeout(() => openSettingsPanel(panel), 150);
}

function bootstrap() {
    // Thứ tự quan trọng: pet.js phải đăng ký listener bus trước khi chat.js phát sự kiện.
    initPet();
    initChat();
    initSessionUi();
    bindNativeCallbacks();

    // "Tiếp tục nơi đã dừng": mở lại phiên gần nhất rồi dựng lại khung chat.
    restoreLatestSession();
    renderTranscript();

    initDrag();
    initFileDrop();
    initBoneContext();
    initSuggestions();
    initRagSettings();
    initLlmSettings();
    initSettingsPanels();
    initSettingsMenu();
    initEyeLeo();

    // Cửa sổ khít đúng vùng chat + pet (và mở rộng khi có bảng thiết lập).
    initWindowFit();

    // Nạp thiết lập (xưng hô, RAG, LLM) để giao diện hiển thị đúng ngay từ đầu.
    native.getSettings();

    // Nếu được khởi động kèm #panel=<tên> (menu GNOME Shell) thì mở bảng đó.
    openPanelFromHash();

    // Khởi động: vẫy đuôi chào mừng, hẹn giờ tự ngủ nếu không tương tác.
    // Giao diện chạy ĐỘC LẬP với dịch vụ AI: chỉ khi người dùng bấm vào chú cún
    // hoặc vào ô nhập liệu thì dịch vụ AI mới được khởi động (xem pet.wake()).
    setPetState("welcoming");
    if (els.statusLabel) {
        els.statusLabel.textContent =
            "Sẵn sàng — bấm vào em hoặc ô nhập để bắt đầu";
    }
    scheduleStartupSleep();
}

bootstrap();
