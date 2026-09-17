// ============================================================================
// features/settings/rag-docs-ui.js — Hiển thị danh sách và quản lý tài liệu RAG
// ============================================================================

import { els } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { getAddressing } from "../../core/state.js";
import { escapeHtml } from "../../core/utils.js";

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
