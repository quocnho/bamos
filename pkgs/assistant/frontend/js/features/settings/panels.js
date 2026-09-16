// ============================================================================
// features/settings/panels.js — Mở bảng thiết lập từ bên ngoài ứng dụng
// ----------------------------------------------------------------------------
// Menu sổ xuống trên thanh trên cùng của GNOME Shell gọi vào backend Go; backend
// gọi `window.openSettingsPanel('<tên>')`. Module này định tuyến tên bảng sang
// đúng bảng thiết lập đang có trong ứng dụng:
//   rag    -> Tri thức RAG
//   llm    -> LLM / SLM
//   eyeleo -> Bảo vệ mắt (EyeLeo)
//   about  -> Giới thiệu BamAI
// Tên không nhận diện được sẽ mở trang Giới thiệu.
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { openRagSettings } from "./rag-settings.js";
import { openLlmSettings } from "./llm-settings.js";
import { openEyeleoSettings } from "../eyeleo/controller.js";
import { openSystemInspectModal } from "../system-inspect.js";
import { openWakaModal } from "../wakatracker-ui.js";
import { openProfileModal } from "../profile-ui.js";
import { openEmbedSettings } from "./embed-settings.js";
import { openAppearanceSettings } from "../appearance/appearance-ui.js";

const PANELS = {
    appearance: openAppearanceSettings,
    rag: openRagSettings,
    llm: openLlmSettings,
    eyeleo: openEyeleoSettings,
    system: openSystemInspectModal,
    waka: openWakaModal,
    profile: openProfileModal,
    embed: openEmbedSettings,
    about: () => show(els.aboutModal),
};

/** Mở một bảng thiết lập theo tên (dùng cho menu GNOME Shell / IPC). */
export function openSettingsPanel(name) {
    const key = String(name || "")
        .trim()
        .toLowerCase();
    const open = PANELS[key] || PANELS.about;
    native.log(`openSettingsPanel(${key})`);
    open();
}

function closeAbout() {
    hide(els.aboutModal);
}

export function initSettingsPanels() {
    if (els.btnCloseAbout) {
        els.btnCloseAbout.addEventListener("click", closeAbout);
    }
    if (els.btnAboutClose) {
        els.btnAboutClose.addEventListener("click", closeAbout);
    }

    // Mọi nút có data-url và mọi liên kết http(s) đều mở bằng trình duyệt hệ
    // thống — KHÔNG để WebView tự nạp URL (sẽ thay mất giao diện ứng dụng).
    document.addEventListener("click", (e) => {
        const target = e.target;
        if (!target || !target.closest) return;

        const linkButton = target.closest("[data-url]");
        if (linkButton) {
            e.preventDefault();
            native.openUrl(linkButton.dataset.url);
            return;
        }

        const anchor = target.closest("a[href]");
        if (anchor) {
            const href = anchor.getAttribute("href") || "";
            if (/^https?:/i.test(href)) {
                e.preventDefault();
                native.openUrl(href);
            }
        }
    });

    // Backend Go gọi trực tiếp: evalJS("window.openSettingsPanel('rag')").
    window.openSettingsPanel = openSettingsPanel;
}
