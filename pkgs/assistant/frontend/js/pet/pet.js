// ============================================================================
// pet/pet.js — Vòng đời & hiệu ứng của chú cún
// ----------------------------------------------------------------------------
// Quản lý trạng thái hiển thị (state-*), hiệu ứng vui vẻ, đánh thức / cho ngủ
// và hai bộ đếm thời gian: chào mừng lúc khởi động và tự nghỉ khi không dùng.
//
// Đây là module DUY NHẤT import chat.js (để hiển thị lời nhắn). Chiều phụ
// thuộc một hướng nên không có import vòng:
//   drag.js / dragdrop.js / bone.js  ->  pet.js  ->  chat.js
// ============================================================================

import { els, show, hide, isHidden } from "../core/dom.js";
import { bus } from "../core/bus.js";
import {
    getPetState,
    setPetState,
    isAiWoken,
    setAiWoken,
    getAddressing,
} from "../core/state.js";
import { escapeHtml } from "../core/utils.js";
import { native } from "../core/native.js";
import * as chat from "../chat/chat.js";

const STARTUP_TIMEOUT_MS = 60 * 1000; // 1 phút không tương tác -> ngủ canh nhà
const INACTIVITY_TIMEOUT_MS = 5 * 60 * 1000; // 5 phút: không dùng AI -> tạm nghỉ

let startupTimer = null;
let inactivityTimer = null;
let alwaysOnTop = true;

// ---------------------------------------------------------------------------
// Trạng thái hiển thị
// ---------------------------------------------------------------------------

/**
 * Cập nhật lớp `state-*` trên <body> nhưng GIỮ LẠI các lớp khác
 * (ví dụ exercise-* dùng cho hoạt hoạ bài tập mắt).
 */
function applyBodyState(state) {
    const preserved = document.body.className
        .split(/\s+/)
        .filter((cls) => cls && !cls.startsWith("state-"));
    preserved.push(`state-${state}`);
    document.body.className = preserved.join(" ");
}

/** Hiệu ứng được vuốt ve: bung tim + trạng thái happy trong 1.5s. */
export function happy() {
    if (els.heartBurst) {
        els.heartBurst.classList.add("animate");
        setTimeout(() => els.heartBurst.classList.remove("animate"), 600);
    }

    setPetState("happy");
    setTimeout(() => {
        if (getPetState() === "happy") {
            setPetState(isAiWoken() ? "idle" : "sleeping");
        }
    }, 1500);
}

// ---------------------------------------------------------------------------
// Đánh thức / cho ngủ
// ---------------------------------------------------------------------------

/** Cho cún nằm xuống ngủ canh nhà (tiết kiệm tài nguyên). */
export function sleep() {
    setPetState("sleeping");
    hide(els.speechBubble);
}

/** Hiển thị bong bóng chat. */
export function showBubble() {
    show(els.speechBubble);
}

/** Ẩn bong bóng chat. */
export function hideBubble() {
    hide(els.speechBubble);
}

/**
 * Bắt đầu một phiên làm việc với AI: đánh thức backend và mở bong bóng chat.
 * Chỉ gọi khi AI chưa thức.
 */
function startAiSession() {
    setAiWoken(true);
    happy();
    showBubble();
    els.statusLabel.textContent = "Đang khởi động toàn bộ AI & RAG...";
    chat.showMessage(`
      <div class="msg msg-ai">
        <div class="msg-body">
          🐶 <b>Gâu gâu!</b> Em đã thức dậy phục vụ ${escapeHtml(getAddressing())} rồi đây ạ! Đang khởi động llama-server và cơ sở tri thức... Vui lòng đợi em trong giây lát nhé!
        </div>
      </div>
    `);
    native.wakeAI();
}

/** Mở bong bóng chat và đưa con trỏ vào ô nhập liệu. */
function openBubbleForChat() {
    showBubble();
    chat.focusInput();
    setPetState("idle");
}

/**
 * Bấm 1 lần vào chú cún: LUÔN mở khung chat (không ẩn).
 * Trước đây hàm này là toggle bật/tắt bong bóng nên bấm Enter hoặc bấm cún
 * khi chat đang mở lại làm khung chat biến mất. Muốn ẩn chat thì dùng nút
 * thu nhỏ (−) trên header.
 */
export function wake() {
    clearStartupTimer();

    if (!isAiWoken()) {
        startAiSession();
    } else if (isHidden(els.speechBubble)) {
        openBubbleForChat();
    } else {
        chat.focusInput();
    }

    resetInactivityTimer();
}

// ---------------------------------------------------------------------------
// Bộ đếm thời gian
// ---------------------------------------------------------------------------

function clearStartupTimer() {
    if (startupTimer) {
        clearTimeout(startupTimer);
        startupTimer = null;
    }
}

/** Không tương tác sau khi mở app -> tự ngủ. */
export function scheduleStartupSleep() {
    clearStartupTimer();
    startupTimer = setTimeout(() => {
        if (!isAiWoken()) sleep();
    }, STARTUP_TIMEOUT_MS);
}

/** Làm mới bộ đếm "không dùng AI thì tạm nghỉ". */
export function resetInactivityTimer() {
    if (inactivityTimer) clearTimeout(inactivityTimer);
    if (!isAiWoken()) return;

    inactivityTimer = setTimeout(() => {
        console.log(
            "[BamAI] 5 phút không tương tác -> Kiểm tra thói quen người dùng để ngủ/tắt dịch vụ AI...",
        );
        native.evaluateSleepOrStop();
        setAiWoken(false);
        sleep();
        els.statusLabel.textContent = "Đã tạm nghỉ để tiết kiệm tài nguyên";
    }, INACTIVITY_TIMEOUT_MS);
}

// ---------------------------------------------------------------------------
// Sự kiện giao diện
// ---------------------------------------------------------------------------

function onCloseClick(e) {
    e.stopPropagation();
    els.statusLabel.textContent = "Đang đóng ứng dụng và tắt AI/RAG...";
    if (!native.closeApp()) {
        hideBubble();
    }
}

function applyAlwaysOnTopUi() {
    els.btnAlwaysOnTop.classList.toggle("active", alwaysOnTop);
    // Đổi biểu tượng để trạng thái ghim rõ ràng: 📌 = đang ghim, 📍 = không ghim.
    els.btnAlwaysOnTop.textContent = alwaysOnTop ? "📌" : "📍";
    els.btnAlwaysOnTop.title = alwaysOnTop
        ? "Đang ghim trên cùng — bấm để bỏ ghim"
        : "Không ghim — bấm để ghim trên cùng";
}

// Đồng bộ trạng thái ghim từ thiết lập đã lưu (gọi khi nạp settings).
// Không gọi lại native vì phía Go đã áp dụng trạng thái này lúc tạo cửa sổ.
export function syncAlwaysOnTop(value) {
    alwaysOnTop = Boolean(value);
    applyAlwaysOnTopUi();
}

function onAlwaysOnTopClick(e) {
    e.stopPropagation();
    alwaysOnTop = !alwaysOnTop;
    applyAlwaysOnTopUi();
    // Áp dụng ngay cho cửa sổ và lưu lại cho lần chạy sau.
    native.setAlwaysOnTop(alwaysOnTop);
    native.saveSettings({ always_on_top: alwaysOnTop });
    els.statusLabel.textContent = alwaysOnTop
        ? "📌 Đã ghim cửa sổ trên cùng"
        : "Đã bỏ ghim cửa sổ (không nổi lên trên nữa)";
}

// ---------------------------------------------------------------------------
// Khởi tạo
// ---------------------------------------------------------------------------
export function initPet() {
    bus.on("pet:state", applyBodyState);
    bus.on("session:ensure-awake", wake);
    bus.on("session:touch", resetInactivityTimer);

    els.btnMinimize.addEventListener("click", (e) => {
        e.stopPropagation();
        hideBubble();
    });
    els.btnClose.addEventListener("click", onCloseClick);
    if (els.btnAlwaysOnTop) {
        els.btnAlwaysOnTop.addEventListener("click", onAlwaysOnTopClick);
    }
    applyAlwaysOnTopUi();
}
