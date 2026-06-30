#!/usr/bin/env python3
"""
BamOS Portal — GTK4 first-boot setup wizard for BamOS
Adapted from Bazzite Portal (ublue-os/yafti-gtk)
Supports Bazzite-style YAML format with id/title/description/default/status_script/options

License: GPL-3.0
"""

import argparse
import os
import subprocess
import sys
import threading

import gi
import yaml

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk

# ── Constants ────────────────────────────────────────────────────────────────
APP_ID = "io.bamos.Portal"
APP_TITLE = "BamOS Portal"
DEFAULT_WINDOW_WIDTH = 850
DEFAULT_WINDOW_HEIGHT = 650
DEFAULT_ICON = "emblem-system-symbolic"

STATUS_ICONS = {
    "pass": "emblem-ok-symbolic",
    "fail": "emblem-important-symbolic",
    "pending": "emblem-system-symbolic",
    "running": "emblem-default-symbolic",
}


def escape_markup(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def run_script(script, capture=False):
    """Run a bash script, optionally capturing output."""
    try:
        if capture:
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-lc", script],
                capture_output=True,
                text=True,
                timeout=600,
            )
            return result.returncode, result.stdout, result.stderr
        else:
            subprocess.Popen(
                ["bash", "--noprofile", "--norc", "-lc", script],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return 0, "", ""
    except Exception as e:
        return 1, "", str(e)


# ── Status Checker ───────────────────────────────────────────────────────────
class StatusChecker(threading.Thread):
    """Check if an action is already completed via status_script."""

    def __init__(self, action, callback):
        super().__init__(daemon=True)
        self.action = action
        self.callback = callback
        self.result = "pending"

    def run(self):
        status_script = self.action.get("status_script", "")
        if status_script:
            rc, _, _ = run_script(status_script, capture=True)
            self.result = "pass" if rc == 0 else "pending"
        else:
            self.result = "pending"
        GLib.idle_add(self.callback, self.result)


# ── ActionRow Widget — Bazzite-style ────────────────────────────────────────
class ActionRow(Gtk.Box):
    """A row for one action: title, description, status, run button or options."""

    def __init__(self, action, parent_window):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.action = action
        self.parent_window = parent_window
        self.status = "pending"
        self.option_buttons = {}

        # Top row: title + status
        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_label = Gtk.Label(
            label=f"<b>{escape_markup(action.get('title', 'Action'))}</b>"
        )
        title_label.set_use_markup(True)
        title_label.set_halign(Gtk.Align.START)
        title_label.set_hexpand(True)
        top_row.append(title_label)

        self.status_icon = Gtk.Image.new_from_icon_name(STATUS_ICONS["pending"])
        top_row.append(self.status_icon)
        self.append(top_row)

        # Description
        desc = action.get("description", "")
        if desc:
            desc_label = Gtk.Label(label=escape_markup(desc))
            desc_label.set_wrap(True)
            desc_label.set_halign(Gtk.Align.START)
            desc_label.set_margin_start(4)
            self.append(desc_label)

        # Spinner
        self.spinner = Gtk.Spinner()
        self.spinner.set_visible(False)
        self.append(self.spinner)

        # Bottom row: options or run button
        bottom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        bottom_row.set_margin_top(6)

        self.options = action.get("options", [])
        self.script = action.get("script", "")

        if self.options:
            # Radio button group for options
            first = None
            for opt in self.options:
                btn = Gtk.CheckButton(label=opt.get("label", "Option"))
                btn.set_valign(Gtk.Align.CENTER)
                if first is None:
                    first = btn
                else:
                    btn.set_group(first)
                self.option_buttons[opt.get("id", "")] = btn
                bottom_row.append(btn)

            run_btn = Gtk.Button(label="▶ Run")
            run_btn.set_valign(Gtk.Align.CENTER)
            run_btn.set_halign(Gtk.Align.END)
            run_btn.set_hexpand(True)
            run_btn.connect("clicked", self.on_run_options)
            bottom_row.append(run_btn)
        elif self.script:
            run_btn = Gtk.Button(label="▶ Run")
            run_btn.set_valign(Gtk.Align.CENTER)
            run_btn.set_halign(Gtk.Align.END)
            run_btn.set_hexpand(True)
            run_btn.connect("clicked", self.on_run_script)
            bottom_row.append(run_btn)

        self.append(bottom_row)

        # Check initial status
        self.check_status()

    def check_status(self):
        checker = StatusChecker(self.action, self._on_status)
        checker.start()

    def _on_status(self, result):
        self.status = result
        self.status_icon.set_from_icon_name(STATUS_ICONS[result])

    def set_status(self, status):
        self.status = status
        self.status_icon.set_from_icon_name(STATUS_ICONS[status])

    def on_run_script(self, button):
        self.set_status("running")
        self.spinner.set_visible(True)
        self.spinner.start()

        def run():
            rc, stdout, stderr = run_script(self.script, capture=True)
            GLib.idle_add(self._on_done, rc, stderr)

        thread = threading.Thread(target=run, daemon=True)
        thread.start()

    def on_run_options(self, button):
        """Find selected option and run its script."""
        for opt in self.options:
            oid = opt.get("id", "")
            if oid in self.option_buttons and self.option_buttons[oid].get_active():
                script = opt.get("script", "")
                if script:
                    self.set_status("running")
                    self.spinner.set_visible(True)
                    self.spinner.start()

                    def run():
                        rc, stdout, stderr = run_script(script, capture=True)
                        GLib.idle_add(self._on_done, rc, stderr)

                    thread = threading.Thread(target=run, daemon=True)
                    thread.start()
                return

    def _on_done(self, rc, stderr):
        self.spinner.set_visible(False)
        self.spinner.stop()
        if rc == 0:
            self.set_status("pass")
        else:
            self.set_status("fail")
            if stderr:
                print(f"[ERROR] {self.action.get('id', 'action')}: {stderr[:200]}")


# ── Screen Page ─────────────────────────────────────────────────────────────
class ScreenPage(Gtk.Box):
    """One tab screen: header + description + scrollable action list."""

    def __init__(self, screen, parent_window):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.set_margin_top(16)
        self.set_margin_bottom(16)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Header with icon
        icon_name = screen.get("icon", DEFAULT_ICON)
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        icon = Gtk.Image.new_from_icon_name(icon_name)
        icon.set_pixel_size(36)
        header_box.append(icon)
        title = Gtk.Label(
            label=f"<b><big>{escape_markup(screen.get('title', 'Tab'))}</big></b>"
        )
        title.set_use_markup(True)
        title.set_halign(Gtk.Align.START)
        title.set_valign(Gtk.Align.CENTER)
        title.set_hexpand(True)

        # Run all defaults button
        run_all_btn = Gtk.Button(label="Run All Defaults")
        run_all_btn.set_valign(Gtk.Align.CENTER)
        run_all_btn.set_tooltip_text("Chạy tất cả các mục được đánh dấu mặc định")
        run_all_btn.connect("clicked", lambda b: self.run_all_defaults())
        header_box.append(run_all_btn)
        header_box.append(icon)

        self.append(header_box)

        desc = screen.get("description", "")
        if desc:
            desc_label = Gtk.Label(label=escape_markup(desc))
            desc_label.set_wrap(True)
            desc_label.set_halign(Gtk.Align.START)
            self.append(desc_label)

        # Action list
        self.action_rows = []
        actions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        actions_box.set_margin_top(8)

        for action in screen.get("actions", []):
            row = ActionRow(action, parent_window)
            self.action_rows.append(row)
            # Separator
            sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
            actions_box.append(row)
            if action != screen["actions"][-1]:
                actions_box.append(sep)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_child(actions_box)
        scrolled.set_vexpand(True)
        self.append(scrolled)

    def run_all_defaults(self):
        """Auto-run all actions marked as default=True."""
        for row in self.action_rows:
            if row.action.get("default", False):
                if row.status == "pending":
                    if row.options:
                        row.on_run_options(None)
                    elif row.script:
                        row.on_run_script(None)


# ── Main Window ──────────────────────────────────────────────────────────────
class PortalWindow(Adw.ApplicationWindow):
    def __init__(self, app, screens):
        super().__init__(application=app, title=APP_TITLE)
        self.set_default_size(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT)

        # Toolbar view with flat tabs
        toolbar = Adw.ToolbarView()
        header = Adw.HeaderBar()
        toolbar.add_top_bar(header)

        tab_view = Adw.TabView()
        for screen in screens:
            page_widget = ScreenPage(screen, self)
            tab_page = tab_view.append(page_widget)
            tab_view.get_page(tab_page).set_title(screen.get("title", "Tab"))

        toolbar.set_content(tab_view)
        self.set_content(toolbar)


# ── Application ──────────────────────────────────────────────────────────────
class PortalApp(Adw.Application):
    def __init__(self, screens):
        super().__init__(application_id=APP_ID)
        self.screens = screens

    def do_activate(self):
        window = PortalWindow(self, self.screens)
        window.present()


# ── Main ─────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="BamOS Portal — First-boot setup wizard"
    )
    parser.add_argument(
        "config",
        nargs="?",
        default="/usr/share/bamos/portal/portal.yml",
        help="Path to portal YAML configuration file",
    )
    args = parser.parse_args()

    try:
        with open(args.config, "r") as f:
            config = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Config not found: {args.config}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"YAML error: {e}")
        sys.exit(1)

    # Support both "sections" (legacy) and "screens" (Bazzite-style)
    screens = config.get("screens", config.get("sections", []))
    if not screens:
        print("No screens/sections found in portal config.")
        sys.exit(1)

    # Initialize GTK
    GLib.set_prgname(APP_ID)
    Gtk.init()
    current_de = os.environ.get("XDG_CURRENT_DESKTOP", "").upper()
    if "KDE" not in current_de:
        Adw.init()
    try:
        Gtk.Window.set_default_icon_name(APP_ID)
    except Exception:
        pass

    app = PortalApp(screens)
    app.run(sys.argv)


if __name__ == "__main__":
    main()
