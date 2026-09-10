// ============================================================================
// BamAI Indicator — GNOME Shell extension (ESM, GNOME 45+)
// ----------------------------------------------------------------------------
// Hiện một mục "🐶 BamAI" trên thanh trên cùng của GNOME Shell kèm menu:
//   • Hiện BamAI        → chạy bamos-assistant (đánh thức/đưa cửa sổ lên trên)
//   • Ẩn cửa sổ         → bamos-assistant --hide
//   • Tắt BamAI         → bamos-assistant --quit (dừng AI/RAG rồi thoát)
//
// Extension KHÔNG phụ thuộc API nội bộ của Shell (chỉ St/panel/menu chuẩn) nên
// ổn định qua các phiên bản. Mọi lỗi được bắt để không ảnh hưởng tới Shell.
// ============================================================================

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import St from 'gi://St';
import Gio from 'gi://Gio';

const APP_BIN = 'bamos-assistant';

export default class BamaiIndicator extends Extension {
    enable() {
        this._indicator = new PanelMenu.Button(0.0, 'BamAI', false);

        // y_align = 2 (Clutter.ActorAlign.CENTER) để nhãn nằm giữa chiều cao panel.
        const label = new St.Label({
            text: '🐶 BamAI',
            y_align: 2,
            style_class: 'bamai-panel-label',
        });
        this._indicator.add_child(label);

        this._indicator.menu.addAction('Hiện BamAI', () => this._run([]));
        this._indicator.menu.addAction('Ẩn cửa sổ', () => this._run(['--hide']));
        this._indicator.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._indicator.menu.addAction('Tắt BamAI (dừng AI/RAG)', () =>
            this._run(['--quit']),
        );

        Main.panel.addToStatusArea('bamai-indicator', this._indicator);
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
