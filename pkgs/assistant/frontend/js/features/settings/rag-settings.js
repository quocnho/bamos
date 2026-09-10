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
import { refreshRagIndicator } from "../../chat/chat.js";

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

function selectedAddressing() {
    if (!els.setAddressing) return "Chủ nhân";
    if (els.setAddressing.value === "__custom__") {
        return (els.setAddressingCustom.value || "").trim() || "Chủ nhân";
    }
    return els.setAddressing.value || "Chủ nhân";
}

function fillAddressing(value) {
    const addressing = (value || "Chủ nhân").trim() || "Chủ nhân";
    if (ADDRESSING_PRESETS.includes(addressing)) {
        els.setAddressing.value = addressing;
        toggle(els.setAddressingCustom, false);
        els.setAddressingCustom.value = "";
    } else {
        els.setAddressing.value = "__custom__";
        toggle(els.setAddressingCustom, true);
        els.setAddressingCustom.value = addressing;
    }
    setAddressing(addressing);
}

// ---------------------------------------------------------------------------
// Callback từ Go
// ---------------------------------------------------------------------------

export function handleSettingsLoaded(result) {
    if (!result || !result.settings) return;
    const settings = result.settings;

    if (els.setRagEnabled) els.setRagEnabled.checked = !!settings.enable_rag;
    setRagEnabled(!!settings.enable_rag);

    const topK = Number(settings.rag_top_k) || 3;
    if (els.setRagTopk) els.setRagTopk.value = String(topK);
    if (els.setRagTopkValue) els.setRagTopkValue.textContent = String(topK);

    fillAddressing(settings.addressing);
    refreshRagIndicator();
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
}

function saveSettings() {
    const enabled = els.setRagEnabled ? els.setRagEnabled.checked : true;
    const topK = els.setRagTopk ? parseInt(els.setRagTopk.value, 10) : 3;
    const addressing = selectedAddressing();

    setRagEnabled(enabled);
    setAddressing(addressing);
    refreshRagIndicator();
    setStatus("Đang lưu thiết lập…");

    native.saveSettings({
        enable_rag: enabled,
        rag_top_k: topK,
        addressing,
    });
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

// ---------------------------------------------------------------------------
// Khởi tạo
// ---------------------------------------------------------------------------

export function initRagSettings() {
    if (!els.btnRagSettings) return;

    els.btnRagSettings.addEventListener("click", (e) => {
        e.stopPropagation();
        openModal();
    });

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

    els.setRagEnabled.addEventListener("change", () => {
        setRagEnabled(els.setRagEnabled.checked);
        refreshRagIndicator();
    });

    els.setAddressing.addEventListener("change", () => {
        const custom = els.setAddressing.value === "__custom__";
        toggle(els.setAddressingCustom, custom);
        if (custom) {
            els.setAddressingCustom.focus();
        } else {
            setAddressing(els.setAddressing.value);
        }
    });
    els.setAddressingCustom.addEventListener("input", () => {
        setAddressing(els.setAddressingCustom.value);
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
