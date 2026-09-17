// ============================================================================
// features/settings/rag-settings.js — Bảng thiết lập tri thức RAG (Slim & Modular)
// ============================================================================

import { els, hide, show } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { setRagEnabled, getAddressing } from "../../core/state.js";
import { handleRagDocumentsListed } from "./rag-docs-ui.js";
import { pendingDocs, addFiles, renderPending, clearPending } from "./rag-pending-ui.js";

export { handleRagDocumentsListed };

let clearArmed = false;
let clearTimer = null;

function setStatus(message, kind = "") {
    const node = els.ragStatus;
    if (!node) return;
    node.textContent = message || "";
    node.classList.remove("ok", "error");
    if (kind) node.classList.add(kind);
}

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
    if (val === 0) els.setRagAlphaValue.textContent = "100% FTS5 (Từ khoá chính xác)";
    else if (val === 100) els.setRagAlphaValue.textContent = "100% Vector (Ngữ nghĩa thuần)";
    else els.setRagAlphaValue.textContent = `${val}% Vector • ${100 - val}% FTS5`;
}

export function handleSettingsSaved(result) {
    if (!result) return;
    setStatus(result.ok ? (result.message || "Đã lưu thiết lập.") : (result.message || "Không lưu được."), result.ok ? "ok" : "error");
}

export function handleRagStats(result) {
    if (result && els.ragCountBadge) els.ragCountBadge.textContent = String(result.count || 0);
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
    setStatus(progress.total ? `Đang nạp ${progress.index}/${progress.total}: ${progress.name}` : (progress.message || "Đang xử lý…"));
}

export function handleRagIndexed(result) {
    if (!result) return;
    if (els.ragCountBadge) els.ragCountBadge.textContent = String(result.count || 0);
    if (result.ok) {
        setStatus(result.message || "Đã nạp tri thức.", "ok");
        clearPending();
        native.ragListDocuments();
    } else {
        setStatus(`${result.message || "Nạp tri thức thất bại."}${(result.failures || []).join("; ")}`, "error");
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

export function openRagSettings() {
    show(els.ragSettingsModal);
    setStatus("");
    renderPending();
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
    native.saveSettings({ enable_rag: enabled, rag_top_k: topK, rag_hybrid_alpha: alphaVal });
}

function indexDocuments() {
    if (pendingDocs.length === 0) return;
    setStatus("Đang nạp tài liệu vào tri thức…");
    if (els.btnRagIndex) els.btnRagIndex.disabled = true;
    native.ragAddDocuments(pendingDocs.map((doc) => ({ name: doc.name, content: doc.content })));
}

function clearKnowledge() {
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
    if (clearTimer) clearTimeout(clearTimer);
    clearTimer = null;
    if (els.btnRagClear) els.btnRagClear.textContent = "🗑️ Xoá toàn bộ";
}

export function initRagSettings() {
    els.btnCloseRagSettings.addEventListener("click", () => hide(els.ragSettingsModal));
    els.btnSaveRagSettings.addEventListener("click", saveSettings);
    els.btnRagIndex.addEventListener("click", indexDocuments);
    els.btnRagClear.addEventListener("click", clearKnowledge);

    els.setRagTopk.addEventListener("input", () => {
        if (els.setRagTopkValue) els.setRagTopkValue.textContent = els.setRagTopk.value;
    });
    if (els.setRagAlpha) {
        els.setRagAlpha.addEventListener("input", () => updateAlphaLabel(parseInt(els.setRagAlpha.value, 10)));
    }
    if (els.btnRefreshRagDocs) {
        els.btnRefreshRagDocs.addEventListener("click", () => native.ragListDocuments());
    }
    els.setRagEnabled.addEventListener("change", () => setRagEnabled(els.setRagEnabled.checked));

    els.ragDropzone.addEventListener("click", () => els.ragFileInput.click());
    els.ragFileInput.addEventListener("change", (e) => {
        addFiles(Array.from(e.target.files || []));
        e.target.value = "";
    });

    ["dragenter", "dragover"].forEach((evt) =>
        els.ragDropzone.addEventListener(evt, (e) => {
            e.preventDefault();
            els.ragDropzone.classList.add("dragover");
        })
    );
    ["dragleave", "drop"].forEach((evt) =>
        els.ragDropzone.addEventListener(evt, (e) => {
            e.preventDefault();
            els.ragDropzone.classList.remove("dragover");
        })
    );
    els.ragDropzone.addEventListener("drop", (e) => {
        if (e.dataTransfer && e.dataTransfer.files) addFiles(Array.from(e.dataTransfer.files));
    });

    renderPending();
}
