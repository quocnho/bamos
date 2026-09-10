// ============================================================================
// core/state.js — Trạng thái phiên làm việc dùng chung
// ----------------------------------------------------------------------------
// Nguồn sự thật duy nhất (single source of truth) cho vài cờ trạng thái nhỏ
// nhưng được nhiều module dùng: trạng thái chú cún, AI đã thức chưa, RAG bật
// hay tắt, cách xưng hô. Việc thay đổi trạng thái sẽ phát sự kiện qua bus để
// các module giao diện cập nhật mà không cần gọi trực tiếp lẫn nhau.
// ============================================================================

import { bus } from "./bus.js";

const session = {
    // Trạng thái hiển thị của chú cún: welcoming | idle | thinking | talking | happy | sleeping
    petState: "welcoming",
    aiWoken: false,
    useRag: true,
    addressing: "Chủ nhân",
};

// ---------------------------------------------------------------------------
// Trạng thái chú cún
// ---------------------------------------------------------------------------
export function getPetState() {
    return session.petState;
}

export function setPetState(next) {
    session.petState = next;
    bus.emit("pet:state", next);
}

// ---------------------------------------------------------------------------
// AI backend đã được đánh thức chưa
// ---------------------------------------------------------------------------
export function isAiWoken() {
    return session.aiWoken;
}

export function setAiWoken(value) {
    session.aiWoken = Boolean(value);
}

// ---------------------------------------------------------------------------
// RAG (tri thức nội bộ) đang bật hay tắt
// ---------------------------------------------------------------------------
export function isRagEnabled() {
    return session.useRag;
}

export function setRagEnabled(value) {
    session.useRag = Boolean(value);
    bus.emit("rag:change", session.useRag);
}

// ---------------------------------------------------------------------------
// Cách xưng hô (dùng cho nhãn câu hỏi và system prompt phía giao diện)
// ---------------------------------------------------------------------------
export function getAddressing() {
    return session.addressing || "Chủ nhân";
}

export function setAddressing(value) {
    const next = (value || "").trim() || "Chủ nhân";
    if (next === session.addressing) return;
    session.addressing = next;
    bus.emit("addressing:change", next);
}
