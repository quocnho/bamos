// ============================================================================
// features/settings/rag-pending-ui.js — Xử lý danh sách tài liệu chờ nạp & đọc file
// ============================================================================

import { els } from "../../core/dom.js";

/** @type {{name:string, content:string}[]} */
export let pendingDocs = [];

export function clearPending() {
    pendingDocs = [];
    renderPending();
}

function readFileAsText(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result || ""));
        reader.onerror = () => reject(reader.error);
        reader.readAsText(file);
    });
}

export function renderPending() {
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

export async function addFiles(fileList) {
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
