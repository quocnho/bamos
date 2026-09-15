// ============================================================================
// features/settings/embed-settings.js — Studio Cấu Hình Nhúng & Whitelist
// ----------------------------------------------------------------------------
// Quản lý:
//   1. Tùy biến thông số widget (Host, Port, Vị trí, Màu sắc, Tiêu đề, RAG)
//   2. Live preview thời gian thực và sinh mã nhúng 1-click copy
//   3. CRUD Danh sách trắng Domain (Domain Whitelist) với Tìm kiếm & Sắp xếp
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { native } from "../../core/native.js";

let currentConfig = null;
let whitelistItems = [];
let editingItemId = null;

export function openEmbedSettings() {
    show(els.embedSettingsModal);
    switchTab("studio");
    if (native.getSettings) {
        native.getSettings();
    }
}

export function closeEmbedSettings() {
    hide(els.embedSettingsModal);
    hide(els.domainEditorModal);
}

function switchTab(tabName) {
    if (tabName === "studio") {
        els.tabEmbedStudio.classList.add("active");
        els.tabEmbedWhitelist.classList.remove("active");
        show(els.panelEmbedStudio);
        hide(els.panelEmbedWhitelist);
    } else {
        els.tabEmbedStudio.classList.remove("active");
        els.tabEmbedWhitelist.classList.add("active");
        hide(els.panelEmbedStudio);
        show(els.panelEmbedWhitelist);
        renderWhitelistTable();
    }
}

// ---------------------------------------------------------------------------
// 1. Cập Nhật Giao Diện Từ Cấu Hình Được Nạp (Go -> JS)
// ---------------------------------------------------------------------------
export function handleSettingsLoaded(result) {
    if (!result || !result.settings) return;
    currentConfig = result.settings;
    const w = currentConfig.widget || {};

    // Điền giá trị vào form Studio
    els.cfgEmbedPort.value = w.port || "9195";
    els.cfgEmbedHost.value = w.host || "127.0.0.1";
    els.cfgEmbedPosition.value = w.position || "bottom-right";
    els.cfgEmbedColor.value = w.primary_color || "linear-gradient(135deg, #FF9F43 0%, #EE5253 100%)";
    els.cfgEmbedTitle.value = w.title || "BamOS Copilot";
    els.cfgEmbedRAG.checked = w.default_rag !== false;

    // Điền Whitelist
    els.cfgEnforceWhitelist.checked = !!w.enforce_whitelist;
    whitelistItems = Array.isArray(w.whitelist) ? [...w.whitelist] : [];

    updateStudioPreviewAndCode();
    renderWhitelistTable();
}

export function handleSettingsSaved(result) {
    if (!result) return;
    if (result.ok) {
        els.embedSaveStatus.textContent = "✓ Đã lưu thành công!";
        setTimeout(() => {
            els.embedSaveStatus.textContent = "";
        }, 2500);
        if (result.settings) {
            currentConfig = result.settings;
        }
    } else {
        els.embedSaveStatus.textContent = "⚠️ Lỗi: " + (result.message || "");
    }
}

// ---------------------------------------------------------------------------
// 2. Studio Live Preview & Code Generator
// ---------------------------------------------------------------------------
function updateStudioPreviewAndCode() {
    const port = els.cfgEmbedPort.value.trim() || "9195";
    const host = els.cfgEmbedHost.value;
    const position = els.cfgEmbedPosition.value;
    const color = els.cfgEmbedColor.value;
    const title = els.cfgEmbedTitle.value.trim() || "BamOS Copilot";

    // Cập nhật Live Preview
    els.miniPreviewTitle.textContent = title;
    els.miniFloatingBtn.style.background = color;
    els.miniChatHeader.style.background = color.startsWith("linear-gradient") ? color : "#1e293b";

    if (position === "bottom-left") {
        els.miniPreviewStage.style.justifyContent = "flex-start";
        const card = els.miniPreviewStage.querySelector(".mini-chat-card");
        if (card) {
            card.style.right = "auto";
            card.style.left = "12px";
        }
    } else {
        els.miniPreviewStage.style.justifyContent = "flex-end";
        const card = els.miniPreviewStage.querySelector(".mini-chat-card");
        if (card) {
            card.style.left = "auto";
            card.style.right = "12px";
        }
    }

    // Sinh mã script nhúng
    const hostTarget = host === "0.0.0.0" ? window.location.hostname || "127.0.0.1" : host;
    const scriptSrc = `http://${hostTarget}:${port}/embed.js`;
    const code = `<script src="${scriptSrc}" async defer></script>`;
    els.generatedEmbedCode.textContent = code;
}

function saveEmbedConfig() {
    if (!currentConfig) currentConfig = {};
    const w = currentConfig.widget || {};

    w.port = els.cfgEmbedPort.value.trim() || "9195";
    w.host = els.cfgEmbedHost.value;
    w.position = els.cfgEmbedPosition.value;
    w.primary_color = els.cfgEmbedColor.value;
    w.title = els.cfgEmbedTitle.value.trim() || "BamOS Copilot";
    w.default_rag = els.cfgEmbedRAG.checked;
    w.enforce_whitelist = els.cfgEnforceWhitelist.checked;
    w.whitelist = whitelistItems;

    currentConfig.widget = w;
    els.embedSaveStatus.textContent = "Đang lưu...";
    native.saveSettings(currentConfig);
}

// ---------------------------------------------------------------------------
// 3. Domain Whitelist Manager (Tìm Kiếm, Sắp Xếp, Thêm, Sửa, Xóa)
// ---------------------------------------------------------------------------
function renderWhitelistTable() {
    const search = (els.whitelistSearchInput.value || "").trim().toLowerCase();
    const sortMode = els.whitelistSortSelect.value;

    // Lọc theo từ khóa tìm kiếm
    let filtered = whitelistItems.filter((item) => {
        const d = (item.domain || "").toLowerCase();
        const n = (item.note || "").toLowerCase();
        return d.includes(search) || n.includes(search);
    });

    // Sắp xếp
    filtered.sort((a, b) => {
        if (sortMode === "domain-asc") {
            return (a.domain || "").localeCompare(b.domain || "");
        } else if (sortMode === "domain-desc") {
            return (b.domain || "").localeCompare(a.domain || "");
        } else if (sortMode === "newest") {
            return (b.created_at || "").localeCompare(a.created_at || "");
        } else if (sortMode === "oldest") {
            return (a.created_at || "").localeCompare(b.created_at || "");
        }
        return 0;
    });

    els.whitelistTableBody.innerHTML = "";
    if (filtered.length === 0) {
        show(els.whitelistEmptyState);
        return;
    }
    hide(els.whitelistEmptyState);

    filtered.forEach((item) => {
        const tr = document.createElement("tr");

        // Cột Toggle Enable
        const tdToggle = document.createElement("td");
        const chk = document.createElement("input");
        chk.type = "checkbox";
        chk.checked = !!item.enabled;
        chk.title = item.enabled ? "Đang bật" : "Đang tắt";
        chk.addEventListener("change", () => {
            item.enabled = chk.checked;
            saveEmbedConfig();
        });
        tdToggle.appendChild(chk);

        // Cột Domain
        const tdDomain = document.createElement("td");
        tdDomain.className = "wl-domain-text";
        tdDomain.textContent = item.domain;
        if (!item.enabled) tdDomain.style.opacity = "0.5";

        // Cột Ghi chú
        const tdNote = document.createElement("td");
        tdNote.className = "wl-note-text";
        tdNote.textContent = item.note || "—";

        // Cột Ngày tạo
        const tdDate = document.createElement("td");
        tdDate.style.color = "#94a3b8";
        tdDate.textContent = item.created_at || "—";

        // Cột Thao tác (Sửa & Xóa)
        const tdActions = document.createElement("td");
        tdActions.className = "wl-actions-cell";

        const btnEdit = document.createElement("button");
        btnEdit.className = "btn-wl-action";
        btnEdit.title = "Sửa domain";
        btnEdit.textContent = "✏️";
        btnEdit.addEventListener("click", () => openEditDomainModal(item));

        const btnDel = document.createElement("button");
        btnDel.className = "btn-wl-action";
        btnDel.title = "Xóa domain này";
        btnDel.textContent = "🗑️";
        btnDel.addEventListener("click", () => deleteDomain(item.id));

        tdActions.appendChild(btnEdit);
        tdActions.appendChild(btnDel);

        tr.appendChild(tdToggle);
        tr.appendChild(tdDomain);
        tr.appendChild(tdNote);
        tr.appendChild(tdDate);
        tr.appendChild(tdActions);

        els.whitelistTableBody.appendChild(tr);
    });
}

function openAddDomainModal() {
    editingItemId = null;
    els.domainEditorTitle.textContent = "➕ Thêm Domain Whitelist";
    els.editDomainId.value = "";
    els.editDomainInput.value = "";
    els.editDomainNote.value = "";
    els.editDomainEnabled.checked = true;
    show(els.domainEditorModal);
    els.editDomainInput.focus();
}

function openEditDomainModal(item) {
    editingItemId = item.id;
    els.domainEditorTitle.textContent = "✏️ Chỉnh Sửa Domain";
    els.editDomainId.value = item.id;
    els.editDomainInput.value = item.domain || "";
    els.editDomainNote.value = item.note || "";
    els.editDomainEnabled.checked = !!item.enabled;
    show(els.domainEditorModal);
    els.editDomainInput.focus();
}

function closeDomainEditorModal() {
    hide(els.domainEditorModal);
}

function saveDomainItem() {
    const domain = els.editDomainInput.value.trim();
    const note = els.editDomainNote.value.trim();
    const enabled = els.editDomainEnabled.checked;

    if (!domain) {
        alert("Vui lòng nhập tên miền hoặc origin!");
        return;
    }

    if (editingItemId) {
        // Cập nhật
        const idx = whitelistItems.findIndex((x) => x.id === editingItemId);
        if (idx !== -1) {
            whitelistItems[idx].domain = domain;
            whitelistItems[idx].note = note;
            whitelistItems[idx].enabled = enabled;
        }
    } else {
        // Thêm mới
        const today = new Date().toISOString().split("T")[0];
        whitelistItems.unshift({
            id: "wl-" + Date.now(),
            domain: domain,
            note: note,
            enabled: enabled,
            created_at: today,
        });
    }

    closeDomainEditorModal();
    renderWhitelistTable();
    saveEmbedConfig();
}

function deleteDomain(id) {
    if (!confirm("Bạn có chắc chắn muốn xóa domain này khỏi danh sách trắng?")) return;
    whitelistItems = whitelistItems.filter((x) => x.id !== id);
    renderWhitelistTable();
    saveEmbedConfig();
}

// ---------------------------------------------------------------------------
// 4. Khởi Tạo Sự Kiện (Events)
// ---------------------------------------------------------------------------
export function initEmbedSettings() {
    // Đóng mở modal
    if (els.btnCloseEmbedSettings) {
        els.btnCloseEmbedSettings.addEventListener("click", closeEmbedSettings);
    }
    if (els.btnCloseDomainEditor) {
        els.btnCloseDomainEditor.addEventListener("click", closeDomainEditorModal);
    }

    // Tabs
    if (els.tabEmbedStudio) {
        els.tabEmbedStudio.addEventListener("click", () => switchTab("studio"));
    }
    if (els.tabEmbedWhitelist) {
        els.tabEmbedWhitelist.addEventListener("click", () => switchTab("whitelist"));
    }

    // Lắng nghe thay đổi form để cập nhật preview thời gian thực
    [els.cfgEmbedPort, els.cfgEmbedHost, els.cfgEmbedPosition, els.cfgEmbedColor, els.cfgEmbedTitle].forEach((input) => {
        if (input) {
            input.addEventListener("input", updateStudioPreviewAndCode);
            input.addEventListener("change", updateStudioPreviewAndCode);
        }
    });

    if (els.btnSaveEmbedConfig) {
        els.btnSaveEmbedConfig.addEventListener("click", saveEmbedConfig);
    }

    // Nút sao chép mã nhúng
    if (els.btnCopyEmbedCode) {
        els.btnCopyEmbedCode.addEventListener("click", () => {
            const code = els.generatedEmbedCode.textContent;
            navigator.clipboard.writeText(code).then(() => {
                els.copyCodeText.textContent = "✓ Đã sao chép!";
                setTimeout(() => {
                    els.copyCodeText.textContent = "Sao chép mã";
                }, 2000);
            });
        });
    }

    // Whitelist controls
    if (els.whitelistSearchInput) {
        els.whitelistSearchInput.addEventListener("input", renderWhitelistTable);
    }
    if (els.whitelistSortSelect) {
        els.whitelistSortSelect.addEventListener("change", renderWhitelistTable);
    }
    if (els.cfgEnforceWhitelist) {
        els.cfgEnforceWhitelist.addEventListener("change", () => {
            saveEmbedConfig();
        });
    }
    if (els.btnOpenAddDomain) {
        els.btnOpenAddDomain.addEventListener("click", openAddDomainModal);
    }
    if (els.btnSaveDomainItem) {
        els.btnSaveDomainItem.addEventListener("click", saveDomainItem);
    }
}
