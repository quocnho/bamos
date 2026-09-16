// ============================================================================
// features/settings/rag-settings.js — Bảng thiết lập tri thức RAG
// ----------------------------------------------------------------------------
// Chức năng:
//   • Bật/tắt tri thức nội bộ (RAG).
//   • Chọn cách xưng hô (Chủ nhân / Anh / Chị / Bạn / Em / tuỳ chỉnh).
//   • Điều chỉnh số đoạn tri thức dùng cho mỗi câu trả lời (top-k).
//   • Nạp NHIỀU tài liệu cùng lúc (kéo thả hoặc chọn tệp) vào cơ sở tri thức.
//   • Xem số tài liệu hiện có và xoá toàn bộ tri thức.
// ============================================================================

import { els, hide, show, toggle } from "../../core/dom.js";
import { native } from "../../core/native.js";
import {
    setRagEnabled,
    setAddressing,
    getAddressing,
} from "../../core/state.js";

const ADDRESSING_PRESETS = ["Chủ nhân", "Anh", "Chị", "Bạn", "Em"];

/** @type {{name:string, content:string}[]} */
let pendingDocs = [];

// Trạng thái xác nhận 2 bước cho nút xoá tri thức.
let clearArmed = false;
let clearTimer = null;

// ---------------------------------------------------------------------------
// Tiện ích
// ---------------------------------------------------------------------------

function setStatus(message, kind = "") {
    const node = els.ragStatus;
    if (!node) return;
    node.textContent = message || "";
    node.classList.remove("ok", "error");
    if (kind) node.classList.add(kind);
}

function readFileAsText(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result || ""));
        reader.onerror = () => reject(reader.error);
        reader.readAsText(file);
    });
}

function renderPending() {
    const list = els.ragPendingList;
    if (!list) return;
    list.textContent = "";

    if (pendingDocs.length === 0) {
        const empty = document.createElement("div");
        empty.className = "model-empty";
        empty.textContent = "Chưa có tài liệu nào được chọn.";
        list.appendChild(empty);
    } else {
        pendingDocs.forEach((doc, index) => {
            const row = document.createElement("div");
            row.className = "pending-item";

            const name = document.createElement("span");
            name.className = "pending-name";
            name.textContent = doc.name;
            name.title = doc.name;

            const remove = document.createElement("button");
            remove.className = "pending-remove";
            remove.textContent = "×";
            remove.title = "Bỏ tệp này";
            remove.addEventListener("click", () => {
                pendingDocs.splice(index, 1);
                renderPending();
            });

            row.appendChild(name);
            row.appendChild(remove);
            list.appendChild(row);
        });
    }

    if (els.btnRagIndex) {
        els.btnRagIndex.disabled = pendingDocs.length === 0;
    }
}

async function addFiles(fileList) {
    for (const file of fileList) {
        if (pendingDocs.some((doc) => doc.name === file.name)) continue;
        try {
            const content = await readFileAsText(file);
            pendingDocs.push({ name: file.name, content });
        } catch (err) {
            console.warn(`[BamAI RAG] Không đọc được ${file.name}:`, err);
        }
    }
    renderPending();
}

// ---------------------------------------------------------------------------
// Callback từ Go
// ---------------------------------------------------------------------------

export function handleSettingsLoaded(result) {
    if (!result || !result.settings) return;
    const settings = result.settings;

    if (els.setRagEnabled) els.setRagEnabled.checked = !!settings.enable_rag;
    setRagEnabled(!!settings.enable_rag);

    const topK = Number(settings.rag_top_k) || 4;
    if (els.setRagTopk) els.setRagTopk.value = String(topK);
    if (els.setRagTopkValue) els.setRagTopkValue.textContent = String(topK);

    const alpha = settings.rag_hybrid_alpha !== undefined ? Math.round(settings.rag_hybrid_alpha * 100) : 65;
    if (els.setRagAlpha) els.setRagAlpha.value = String(alpha);
    updateAlphaLabel(alpha);
}

function updateAlphaLabel(val) {
    if (!els.setRagAlphaValue) return;
    if (val === 0) {
        els.setRagAlphaValue.textContent = "100% FTS5 (Từ khoá chính xác)";
    } else if (val === 100) {
        els.setRagAlphaValue.textContent = "100% Vector (Ngữ nghĩa thuần)";
    } else {
        els.setRagAlphaValue.textContent = `${val}% Vector • ${100 - val}% FTS5`;
    }
}

export function handleSettingsSaved(result) {
    if (!result) return;
    if (result.ok) {
        setStatus(result.message || "Đã lưu thiết lập.", "ok");
    } else {
        setStatus(result.message || "Không lưu được thiết lập.", "error");
    }
}

export function handleRagStats(result) {
    if (!result) return;
    if (els.ragCountBadge) {
        els.ragCountBadge.textContent = String(result.count || 0);
    }
}

export function handleRagDocumentsListed(result) {
    const container = els.ragDocsContainer;
    if (!container) return;
    container.innerHTML = "";

    const docs = result && result.documents ? result.documents : [];
    if (docs.length === 0) {
        container.innerHTML = `<div class="model-empty">Chưa có tài liệu nào trong cơ sở tri thức SQLite.</div>`;
        return;
    }

    docs.forEach((doc) => {
        const row = document.createElement("div");
        row.style.cssText = "display: flex; justify-content: space-between; align-items: center; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 10px; margin-bottom: 5px;";
        row.innerHTML = `
            <div style="min-width: 0; flex: 1;">
                <div style="font-weight: 700; color: #1e293b; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                    📄 ${escapeHtml(doc.source || "Tài liệu")}
                </div>
                <div style="font-size: 11px; color: #64748b;">
                    ${doc.chunks} đoạn tri thức • ${doc.domain || "general"}
                </div>
            </div>
            <button class="mini-del-btn" style="background: none; border: none; color: #ef4444; font-size: 15px; cursor: pointer; padding: 2px 6px;" title="Xoá tài liệu này">🗑️</button>
        `;

        const delBtn = row.querySelector(".mini-del-btn");
        delBtn.addEventListener("click", () => {
            const userTitle = getAddressing() || "Bạn";
            if (confirm(`${userTitle} có chắc chắn muốn xoá tài liệu "${doc.source}" khỏi tri thức không?`)) {
                native.ragDeleteDoc(doc.source);
            }
        });

        container.appendChild(row);
    });
}

export function handleRagDocDeleted(result) {
    if (result && result.ok) {
        setStatus("Đã xoá tài liệu khỏi tri thức.", "ok");
        native.ragListDocuments();
        native.ragStats();
    }
}

export function handleRagIndexProgress(progress) {
    if (!progress) return;
    if (!progress.total) {
        setStatus(progress.message || "Đang xử lý…");
        return;
    }
    setStatus(`Đang nạp ${progress.index}/${progress.total}: ${progress.name}`);
}

export function handleRagIndexed(result) {
    if (!result) return;
    if (els.ragCountBadge)
        els.ragCountBadge.textContent = String(result.count || 0);

    if (result.ok) {
        setStatus(result.message || "Đã nạp tri thức.", "ok");
        pendingDocs = [];
        renderPending();
        native.ragListDocuments();
    } else {
        const details = (result.failures || []).join("; ");
        setStatus(
            `${result.message || "Nạp tri thức thất bại."}${details ? ` (${details})` : ""}`,
            "error",
        );
    }
    if (els.btnRagIndex) els.btnRagIndex.disabled = pendingDocs.length === 0;
}

export function handleRagCleared(result) {
    if (!result) return;
    resetClearButton();
    if (result.ok) {
        if (els.ragCountBadge) els.ragCountBadge.textContent = "0";
        setStatus(result.message || "Đã xoá tri thức.", "ok");
        native.ragListDocuments();
    } else {
        setStatus(result.message || "Không xoá được tri thức.", "error");
    }
}

// ---------------------------------------------------------------------------
// Hành động
// ---------------------------------------------------------------------------

function openModal() {
    show(els.ragSettingsModal);
    setStatus("");
    renderPending();
    // Hiển thị ngay giá trị đã biết để không lưu đè khi người dùng thao tác nhanh.
    fillAddressing(getAddressing());
    native.getSettings();
    native.ragStats();
    native.ragListDocuments();
}

function saveSettings() {
    const enabled = els.setRagEnabled ? els.setRagEnabled.checked : true;
    const topK = els.setRagTopk ? parseInt(els.setRagTopk.value, 10) : 4;
    const alphaVal = els.setRagAlpha ? parseInt(els.setRagAlpha.value, 10) / 100.0 : 0.65;

    setRagEnabled(enabled);
    setStatus("Đang lưu thiết lập…");

    native.saveSettings({
        enable_rag: enabled,
        rag_top_k: topK,
        rag_hybrid_alpha: alphaVal,
    });
}

function escapeHtml(str) {
    if (!str) return "";
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function indexDocuments() {
    if (pendingDocs.length === 0) return;
    setStatus("Đang nạp tài liệu vào tri thức…");
    if (els.btnRagIndex) els.btnRagIndex.disabled = true;
    native.ragAddDocuments(
        pendingDocs.map((doc) => ({ name: doc.name, content: doc.content })),
    );
}

function clearKnowledge() {
    // Xác nhận 2 bước để không phụ thuộc hộp thoại confirm() của WebKit.
    if (!clearArmed) {
        clearArmed = true;
        els.btnRagClear.textContent = "⚠️ Bấm lần nữa để xoá";
        setStatus("Bấm thêm một lần nữa để xác nhận xoá toàn bộ tri thức.");
        clearTimer = setTimeout(resetClearButton, 4000);
        return;
    }
    resetClearButton();
    setStatus("Đang xoá tri thức…");
    native.ragClear();
}

function resetClearButton() {
    clearArmed = false;
    if (clearTimer) {
        clearTimeout(clearTimer);
        clearTimer = null;
    }
    if (els.btnRagClear) els.btnRagClear.textContent = "🗑️ Xoá toàn bộ";
}

/** Mở bảng thiết lập RAG từ bên ngoài (menu GNOME Shell, IPC...). */
export function openRagSettings() {
    openModal();
}

// ---------------------------------------------------------------------------
// Khởi tạo
// ---------------------------------------------------------------------------

export function initRagSettings() {
    els.btnCloseRagSettings.addEventListener("click", () =>
        hide(els.ragSettingsModal),
    );
    els.btnSaveRagSettings.addEventListener("click", saveSettings);
    els.btnRagIndex.addEventListener("click", indexDocuments);
    els.btnRagClear.addEventListener("click", clearKnowledge);

    els.setRagTopk.addEventListener("input", () => {
        if (els.setRagTopkValue) {
            els.setRagTopkValue.textContent = els.setRagTopk.value;
        }
    });

    if (els.setRagAlpha) {
        els.setRagAlpha.addEventListener("input", () => {
            updateAlphaLabel(parseInt(els.setRagAlpha.value, 10));
        });
    }

    if (els.btnRefreshRagDocs) {
        els.btnRefreshRagDocs.addEventListener("click", () => {
            native.ragListDocuments();
        });
    }

    els.setRagEnabled.addEventListener("change", () => {
        setRagEnabled(els.setRagEnabled.checked);
    });

    // Chọn tệp
    els.ragDropzone.addEventListener("click", () => els.ragFileInput.click());
    els.ragFileInput.addEventListener("change", (e) => {
        addFiles(Array.from(e.target.files || []));
        e.target.value = "";
    });

    // Kéo thả tệp vào vùng nạp
    ["dragenter", "dragover"].forEach((eventName) =>
        els.ragDropzone.addEventListener(eventName, (e) => {
            e.preventDefault();
            e.stopPropagation();
            els.ragDropzone.classList.add("dragover");
        }),
    );
    ["dragleave", "drop"].forEach((eventName) =>
        els.ragDropzone.addEventListener(eventName, (e) => {
            e.preventDefault();
            e.stopPropagation();
            els.ragDropzone.classList.remove("dragover");
        }),
    );
    els.ragDropzone.addEventListener("drop", (e) => {
        if (e.dataTransfer && e.dataTransfer.files) {
            addFiles(Array.from(e.dataTransfer.files));
        }
    });

    renderPending();
}
