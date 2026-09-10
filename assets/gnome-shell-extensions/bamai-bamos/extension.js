// ============================================================================
// BamAI Indicator — GNOME Shell extension (ESM, GNOME 45+)
// ----------------------------------------------------------------------------
// Trên thanh trên cùng hiện icon bánh răng (settings). Bấm vào mở menu sổ xuống:
//   • RAG — Tri thức       → mở bảng thiết lập tri thức trong BamAI
//   • LLM / SLM            → mở bảng thiết lập model
//   • Quản lý nghỉ ngơi    → mở bảng nhắc nghỉ mắt
//   • Giới thiệu           → mở trang giới thiệu
//   ───────────────────────
//   • Hiện BamAI  • Ẩn cửa sổ  •  Tắt BamAI (dừng AI/RAG)
//
// Mọi thao tác đều đi qua CLI `bamos-assistant`: nếu ứng dụng đang chạy thì lệnh
// được chuyển tiếp qua API nội bộ của nó, nên extension không cần biết cổng HTTP.
// ============================================================================

import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as PanelMenu from "resource:///org/gnome/shell/ui/panelMenu.js";
import * as PopupMenu from "resource:///org/gnome/shell/ui/popupMenu.js";
import St from "gi://St";
import Gio from "gi://Gio";

const APP_BIN = "bamos-assistant";

// [tên icon symbolic, nhãn, tên bảng thiết lập trong BamAI]
const SETTINGS_ITEMS = [
    ["folder-documents-symbolic", "RAG — Tri thức", "rag"],
    ["application-x-executable-symbolic", "LLM / SLM", "llm"],
    ["view-reveal-symbolic", "Quản lý nghỉ ngơi", "eyeleo"],
    ["help-about-symbolic", "Giới thiệu", "about"],
];

export default class BamaiIndicator extends Extension {
    enable() {
        this._indicator = new PanelMenu.Button(0.0, "Thiết lập BamAI", false);

        // Icon bánh răng làm điểm nhấn "settings" trên thanh trên cùng.
        const icon = new St.Icon({
            icon_name: "emblem-system-symbolic",
            style_class: "system-status-icon bamai-panel-icon",
            y_align: 2, // Clutter.ActorAlign.CENTER
        });
        this._indicator.add_child(icon);

        const menu = this._indicator.menu;

        for (const [iconName, label, panel] of SETTINGS_ITEMS) {
            const item = new PopupMenu.PopupImageMenuItem(label, iconName);
            item.connect("activate", () => this._run(["--settings", panel]));
            menu.addMenuItem(item);
        }

        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        menu.addAction("Hiện BamAI", () => this._run([]));
        menu.addAction("Ẩn cửa sổ", () => this._run(["--hide"]));

        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        menu.addAction("Tắt BamAI (dừng AI/RAG)", () => this._run(["--quit"]));

        Main.panel.addToStatusArea("bamai-indicator", this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }

    /** Chạy bamos-assistant với tham số điều khiển (không chờ, ẩn output). */
    _run(args) {
        try {
            Gio.Subprocess.new(
                [APP_BIN, ...args],
                Gio.SubprocessFlags.STDOUT_SILENCE |
                    Gio.SubprocessFlags.STDERR_SILENCE,
            );
        } catch (error) {
            logError(error, `BamAI Indicator: không chạy được ${APP_BIN}`);
        }
    }
}
