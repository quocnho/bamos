// ============================================================================
// main.js — Điểm khởi động (entry point) của giao diện BamAI
// ----------------------------------------------------------------------------
// Chỉ làm hai việc: khởi tạo các module và nối callback từ Go backend.
// Toàn bộ nghiệp vụ nằm trong các module con:
//
//   core/       dom, state, bus, native, utils, audio, clipboard, tooltip
//   chat/       chat (hội thoại + sao chép), markdown, attachments
//   pet/        pet (vòng đời), drag (di chuyển + double-click), dragdrop
//   features/   bone (bối cảnh thư mục), suggestions (chip tần suất),
//               eyeleo (bảo vệ mắt), settings/{rag-settings, llm-settings}
// ============================================================================

import { setPetState, setAddressing } from "./core/state.js";
import { native } from "./core/native.js";
import { initPet, scheduleStartupSleep, syncAlwaysOnTop } from "./pet/pet.js";
import { initDrag } from "./pet/drag.js";
import { initFileDrop } from "./pet/dragdrop.js";
import {
    initChat,
    handleWaking,
    handleReady,
    handleChunk,
    handleDone,
    handleError,
} from "./chat/chat.js";
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

function bootstrap() {
    // Thứ tự quan trọng: pet.js phải đăng ký listener bus trước khi chat.js phát sự kiện.
    initPet();
    initChat();
    bindNativeCallbacks();

    initDrag();
    initFileDrop();
    initBoneContext();
    initSuggestions();
    initRagSettings();
    initLlmSettings();
    initEyeLeo();

    // Nạp thiết lập (xưng hô, RAG, LLM) để giao diện hiển thị đúng ngay từ đầu.
    native.getSettings();

    // Khởi động: vẫy đuôi chào mừng, hẹn giờ tự ngủ nếu không tương tác.
    setPetState("welcoming");
    scheduleStartupSleep();
}

bootstrap();
