// ============================================================================
// chat/sessions.js — Phiên hội thoại: lưu trữ, mở lại, tạo mới
// ----------------------------------------------------------------------------
// Mỗi PHIÊN gồm một danh sách lượt nói (transcript) + được lưu vào
// localStorage nên mở lại được sau khi tắt/mở ứng dụng. Ngữ cảnh gửi cho model
// được SUY RA từ transcript (không lưu trùng hai nơi).
//
// transcript: [{ role: 'user' | 'assistant', text, at }]
// ============================================================================

import { stripHtml, clip } from "../core/utils.js";

const STORAGE_KEY = "bamai_sessions_v1";
const MAX_SESSIONS = 30; // số phiên lưu gần đây
const MAX_TURNS = 400; // số lượt tối đa trong một phiên (chống phình bộ nhớ)

let current = null;
let pendingTimer = null;
const listeners = new Set();

// ---------------------------------------------------------------------------
// Tiện ích
// ---------------------------------------------------------------------------

function uid() {
    return `s${Date.now().toString(36)}${Math.random().toString(36).slice(2, 7)}`;
}

function emptySession() {
    const now = Date.now();
    return {
        id: uid(),
        title: "",
        createdAt: now,
        updatedAt: now,
        transcript: [],
    };
}

function loadAll() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        const data = raw ? JSON.parse(raw) : null;
        if (data && Array.isArray(data.sessions)) return data.sessions;
    } catch (err) {
        console.warn("[BamAI session] Không đọc được lịch sử:", err);
    }
    return [];
}

function saveAll(sessions) {
    try {
        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify({ version: 1, sessions }),
        );
    } catch (err) {
        console.warn("[BamAI session] Không lưu được lịch sử:", err);
    }
}

function notify() {
    for (const listener of listeners) {
        try {
            listener(getCurrentSession());
        } catch (err) {
            console.warn("[BamAI session] listener lỗi:", err);
        }
    }
}

/** Đăng ký theo dõi thay đổi phiên hiện tại. */
export function onSessionChange(listener) {
    listeners.add(listener);
    return () => listeners.delete(listener);
}

// ---------------------------------------------------------------------------
// Phiên hiện tại
// ---------------------------------------------------------------------------

export function getCurrentSession() {
    if (!current) current = emptySession();
    return current;
}

/** Lưu phiên hiện tại (nếu có nội dung) rồi bắt đầu phiên mới. */
export function startNewSession() {
    persistNow();
    current = emptySession();
    notify();
    return current;
}

/** Thêm một lượt nói vào phiên hiện tại. */
export function appendTurn(role, text) {
    const value = String(text ?? "").trim();
    if (!value) return -1;

    const session = getCurrentSession();
    session.transcript.push({ role, text: value, at: Date.now() });
    if (session.transcript.length > MAX_TURNS) {
        session.transcript.splice(0, session.transcript.length - MAX_TURNS);
    }
    if (!session.title && role === "user") {
        session.title = clip(stripHtml(value), 80);
    }
    session.updatedAt = Date.now();

    persistSoon();
    return session.transcript.length - 1;
}

/** Vị trí lượt kế tiếp sẽ được thêm (dùng để gắn nhãn DOM trước khi stream). */
export function nextTurnIndex() {
    return getCurrentSession().transcript.length;
}

// ---------------------------------------------------------------------------
// Lưu trữ
// ---------------------------------------------------------------------------

function persistNow() {
    const session = getCurrentSession();
    if (session.transcript.length === 0) return;

    const all = loadAll().filter((item) => item.id !== session.id);
    all.push({
        id: session.id,
        title: session.title,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        transcript: session.transcript,
    });
    all.sort((a, b) => (b.updatedAt || 0) - (a.updatedAt || 0));
    saveAll(all.slice(0, MAX_SESSIONS));
}

function persistSoon() {
    if (pendingTimer) return;
    pendingTimer = setTimeout(() => {
        pendingTimer = null;
        persistNow();
        notify();
    }, 400);
}

// ---------------------------------------------------------------------------
// Lịch sử gần đây
// ---------------------------------------------------------------------------

/**
 * Khôi phục phiên gần nhất khi mở ứng dụng ("tiếp tục nơi đã dừng").
 * Chỉ chạy khi phiên hiện tại còn trống. Trả về true nếu đã khôi phục.
 */
export function restoreLatestSession() {
    if (getCurrentSession().transcript.length > 0) return false;

    const sessions = loadAll();
    if (sessions.length === 0) return false;

    const latest = sessions.reduce((a, b) =>
        (b.updatedAt || 0) > (a.updatedAt || 0) ? b : a,
    );
    if (!latest) return false;
    return openSession(latest.id);
}

/** Danh sách phiên gần đây (mới nhất trước), kèm phiên đang mở. */
export function listRecentSessions() {
    const sessions = loadAll();
    const session = getCurrentSession();
    const others = sessions.filter((item) => item.id !== session.id);
    const mine = {
        id: session.id,
        title: session.title || "(phiên đang mở)",
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        transcript: session.transcript,
    };
    return [mine, ...others].filter(
        (item) => item.transcript && item.transcript.length > 0,
    );
}

/** Mở lại một phiên đã lưu. Trả về true nếu tìm thấy. */
export function openSession(id) {
    const session = getCurrentSession();
    if (session.id === id) return true;

    persistNow();
    const found = loadAll().find((item) => item.id === id);
    if (!found) return false;

    current = {
        id: found.id,
        title: found.title || "",
        createdAt: found.createdAt || Date.now(),
        updatedAt: found.updatedAt || Date.now(),
        transcript: Array.isArray(found.transcript) ? found.transcript : [],
    };
    notify();
    return true;
}

/** Xoá một phiên khỏi lịch sử. */
export function deleteSession(id) {
    saveAll(loadAll().filter((item) => item.id !== id));
    if (getCurrentSession().id === id) {
        current = emptySession();
    }
    notify();
}

// ---------------------------------------------------------------------------
// Ngữ cảnh gửi cho model (suy ra từ transcript)
// ---------------------------------------------------------------------------

/**
 * Lấy ngữ cảnh hội thoại gần nhất để gửi kèm câu hỏi mới.
 * Giới hạn cả số lượt, độ dài mỗi lượt và tổng độ dài để không tràn context.
 */
export function currentHistory(
    maxTurns = 10,
    maxCharsPerTurn = 1200,
    maxTotalChars = 6000,
) {
    const turns = getCurrentSession().transcript.slice(-maxTurns);
    const out = [];
    let total = 0;

    // Duyệt từ lượt MỚI NHẤT về trước để ưu tiên ngữ cảnh sát nhất.
    for (let i = turns.length - 1; i >= 0; i--) {
        const turn = turns[i];
        const text = clip(stripHtml(turn.text), maxCharsPerTurn);
        if (!text) continue;
        if (total + text.length > maxTotalChars) break;
        total += text.length;
        out.unshift({ role: turn.role, content: text });
    }
    return out;
}
