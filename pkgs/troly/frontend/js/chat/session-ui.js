// ============================================================================
// chat/session-ui.js — Nút tạo phiên mới (＋) và mở lại hội thoại gần đây (🕘)
// ----------------------------------------------------------------------------
// Hai nút nằm ở góc trên bên phải của khung hội thoại:
//   • ＋ : lưu phiên hiện tại rồi mở một phiên trống.
//   • 🕘 : danh sách các phiên gần đây (bấm để mở lại, có nút xoá).
// ============================================================================

import { els, hide, show } from "../core/dom.js";
import {
    getCurrentSession,
    startNewSession,
    listRecentSessions,
    openSession,
    deleteSession,
} from "./sessions.js";
import { renderTranscript } from "./chat.js";

function formatTime(timestamp) {
    try {
        return new Date(timestamp).toLocaleString("vi-VN", {
            day: "2-digit",
            month: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
        });
    } catch (err) {
        return "";
    }
}

function renderList() {
    const list = els.recentList;
    if (!list) return;
    list.textContent = "";

    const sessions = listRecentSessions();
    if (sessions.length === 0) {
        const empty = document.createElement("div");
        empty.className = "model-empty";
        empty.textContent = "Chưa có hội thoại nào được lưu.";
        list.appendChild(empty);
        return;
    }

    const currentId = getCurrentSession().id;

    for (const session of sessions) {
        const row = document.createElement("div");
        row.className = `session-item${session.id === currentId ? " active" : ""}`;

        const main = document.createElement("div");
        main.className = "session-main";

        const title = document.createElement("div");
        title.className = "session-title";
        title.textContent = session.title || "(không có tiêu đề)";
        title.title = session.title || "";

        const meta = document.createElement("div");
        meta.className = "session-meta";
        meta.textContent = `${session.transcript.length} lượt • ${formatTime(session.updatedAt)}`;

        main.appendChild(title);
        main.appendChild(meta);

        const remove = document.createElement("button");
        remove.className = "session-delete";
        remove.textContent = "🗑";
        remove.title = "Xoá hội thoại này";
        remove.addEventListener("click", (e) => {
            e.stopPropagation();
            deleteSession(session.id);
            renderList();
        });

        row.appendChild(main);
        row.appendChild(remove);
        row.addEventListener("click", () => {
            if (openSession(session.id)) renderTranscript();
            hide(els.recentSessionsModal);
        });

        list.appendChild(row);
    }
}

export function openRecent() {
    renderList();
    show(els.recentSessionsModal);
}

function newSession() {
    startNewSession();
    renderTranscript();
    if (els.statusLabel) {
        els.statusLabel.textContent = "Phiên mới — sẵn sàng phục vụ";
    }
}

export function initSessionUi() {
    if (els.btnNewChat) {
        els.btnNewChat.addEventListener("click", (e) => {
            e.stopPropagation();
            hide(els.recentSessionsModal);
            newSession();
        });
    }

    if (els.btnRecentChat) {
        els.btnRecentChat.addEventListener("click", (e) => {
            e.stopPropagation();
            openRecent();
        });
    }

    if (els.headBtnRecent) {
        els.headBtnRecent.addEventListener("click", (e) => {
            e.stopPropagation();
            openRecent();
        });
    }

    if (els.btnCloseRecent) {
        els.btnCloseRecent.addEventListener("click", () =>
            hide(els.recentSessionsModal),
        );
    }
}
