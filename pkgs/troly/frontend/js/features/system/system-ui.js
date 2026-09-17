// ============================================================================
// features/system-inspect.js — Bảng giám sát hệ thống, log NixOS và app ngầm
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { native } from "../../core/native.js";

export function openSystemInspectModal() {
    show(els.systemInspectModal);
    runInspection();
}

function runInspection() {
    if (els.systemInspectStatus) {
        els.systemInspectStatus.textContent = "Đang quét nhật ký journalctl và /etc/nixos…";
    }
    native.systemInspect();
}

export function handleSystemInspected(result) {
    if (!result || !result.ok) {
        if (els.systemInspectStatus) els.systemInspectStatus.textContent = "Không thể quét hệ thống";
        return;
    }
    if (els.systemInspectStatus) {
        els.systemInspectStatus.textContent = `Cập nhật lúc: ${result.time || ""}`;
    }

    // Render Issues List
    const issuesContainer = els.systemIssuesList;
    if (issuesContainer) {
        issuesContainer.innerHTML = "";
        const issues = result.issues || [];
        if (issues.length === 0) {
            issuesContainer.innerHTML = `<div class="model-empty" style="color: #2a9d8f;">✨ Hệ thống ổn định, không phát hiện lỗi cấu hình NixOS nào!</div>`;
        } else {
            issues.forEach((issue) => {
                const div = document.createElement("div");
                div.className = "issue-card";
                div.style.cssText = "background: #fff; border: 1px solid #e2e8f0; border-left: 4px solid #e76f51; border-radius: 8px; padding: 8px 10px; font-size: 12px;";

                div.innerHTML = `
                    <div style="font-weight: 700; color: #1e293b; display: flex; justify-content: space-between;">
                        <span>⚠️ ${escapeHtml(issue.title)}</span>
                        <span style="font-size: 10.5px; color: #94a3b8;">${issue.timestamp || ""}</span>
                    </div>
                    <div style="color: #64748b; font-size: 11.5px; margin: 4px 0;">${escapeHtml(issue.description)}</div>
                    <div style="background: rgba(42, 157, 143, 0.08); padding: 5px 8px; border-radius: 5px; color: #2a9d8f; font-weight: 600;">
                        💡 <b>Khuyến nghị:</b> ${escapeHtml(issue.suggestion)}
                    </div>
                `;
                issuesContainer.appendChild(div);
            });
        }
    }

    // Render Idle Apps
    const idleContainer = els.systemIdleAppsList;
    if (idleContainer) {
        idleContainer.innerHTML = "";
        const idleApps = result.idle_apps || [];
        if (idleApps.length === 0) {
            idleContainer.innerHTML = `<div class="model-empty">Không phát hiện ứng dụng chạy ngầm lãng phí bộ nhớ.</div>`;
        } else {
            idleApps.forEach((app) => {
                const div = document.createElement("div");
                div.style.cssText = "display: flex; justify-content: space-between; align-items: center; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 10px; font-size: 12px;";
                div.innerHTML = `
                    <div>
                        <b>${escapeHtml(app.name)}</b> (PID: <code>${app.pid}</code>) — RAM: ${app.memory_mb}
                        <div style="font-size: 11px; color: #64748b;">${escapeHtml(app.suggestion)}</div>
                    </div>
                `;
                idleContainer.appendChild(div);
            });
        }
    }
}

function escapeHtml(str) {
    if (!str) return "";
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export function initSystemInspect() {
    if (els.btnCloseSystemInspect) {
        els.btnCloseSystemInspect.addEventListener("click", () => hide(els.systemInspectModal));
    }
    if (els.btnRunSystemInspect) {
        els.btnRunSystemInspect.addEventListener("click", runInspection);
    }
}
