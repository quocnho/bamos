// ============================================================================
// main.js — Điểm khởi động (entry point) của giao diện BamAI
// ----------------------------------------------------------------------------
// Chỉ làm hai việc: khởi tạo các module và nối callback từ Go backend.
// Toàn bộ nghiệp vụ nằm trong các module con:
//
//   core/      dom, state, bus, native, utils, audio
//   chat/      chat (hội thoại), markdown, attachments
//   pet/       pet (vòng đời), drag (di chuyển), dragdrop (thả tệp)
//   features/  bone (bối cảnh thư mục), suggestions, eyeleo
// ============================================================================

import { setPetState } from "./core/state.js";
import { initPet, scheduleStartupSleep } from "./pet/pet.js";
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

// Callback do Go backend gọi trực tiếp trên window.
function bindNativeCallbacks() {
    window.onAIWaking = handleWaking;
    window.onAIReady = handleReady;
    window.onAIChunk = handleChunk;
    window.onAIDone = handleDone;
    window.onAIError = handleError;
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
    initEyeLeo();

    // Khởi động: vẫy đuôi chào mừng, hẹn giờ tự ngủ nếu không tương tác.
    setPetState("welcoming");
    scheduleStartupSleep();
}

bootstrap();
