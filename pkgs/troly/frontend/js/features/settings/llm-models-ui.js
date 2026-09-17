// ============================================================================
// features/settings/llm-models-ui.js — Hiển thị danh sách model GGUF và tải model
// ============================================================================

import { els } from "../../core/dom.js";
import { native } from "../../core/native.js";

export let activePath = "";

export function setActivePath(p) {
    activePath = p;
}

export function renderModels(result, onSelect) {
    const list = els.llmModelList;
    if (!list) return;
    list.textContent = "";

    const models = (result && result.models) || [];
    if (models.length === 0) {
        const empty = document.createElement("div");
        empty.className = "model-empty";
        empty.textContent = "Chưa có model .gguf nào. Hãy tải model hoặc chép tệp vào thư mục trên.";
        list.appendChild(empty);
        return;
    }

    for (const model of models) {
        const row = document.createElement("div");
        row.className = "model-item";
        if (model.active || model.path === activePath) {
            row.classList.add("active");
        }
        row.title = model.path;

        const name = document.createElement("span");
        name.className = "model-name";
        name.textContent = `${model.active ? "✅ " : ""}${model.name}`;

        const size = document.createElement("span");
        size.className = "model-size";
        size.textContent = model.size_text || "";

        row.appendChild(name);
        row.appendChild(size);

        row.addEventListener("click", () => {
            if (els.llmModelList) {
                Array.from(els.llmModelList.children).forEach((child) => child.classList.remove("active"));
            }
            row.classList.add("active");
            activePath = model.path;
            if (onSelect) onSelect(model);
        });

        list.appendChild(row);
    }
}
