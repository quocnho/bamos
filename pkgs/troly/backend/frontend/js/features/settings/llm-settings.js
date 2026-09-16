// ============================================================================
// features/settings/llm-settings.js — Bảng thiết lập LLM
// ----------------------------------------------------------------------------
// Chức năng:
//   • Chọn nhà cung cấp: local (llama-server) / DeepSeek / OpenAI / Gemini.
//   • Nhập API key cho từng nhà cung cấp đám mây (ẩn khi không dùng).
//   • Quản lý model GGUF cục bộ: liệt kê, chọn model đang dùng, tải từ URL.
//   • Tinh chỉnh temperature, context size, số layer offload GPU.
//   • Kiểm tra kết nối và khởi động lại llama-server.
// ============================================================================

import { els, hide, show, toggle } from "../../core/dom.js";
import { native } from "../../core/native.js";

/** Model đang được chọn trong danh sách. */
let activePath = "";

// ---------------------------------------------------------------------------
// Tiện ích
// ---------------------------------------------------------------------------

function setStatus(message, kind = "") {
    const node = els.llmStatus;
    if (!node) return;
    node.textContent = message || "";
    node.classList.remove("ok", "error");
    if (kind) node.classList.add(kind);
}

function setDownloadStatus(message, percent) {
    const node = els.llmDownloadProgress;
    if (!node) return;
    node.textContent = message || "";
    if (typeof percent === "number") {
        const bar = document.createElement("div");
        bar.className = "progress-bar";
        const fill = document.createElement("span");
        fill.style.width = `${Math.max(0, Math.min(100, percent))}%`;
        bar.appendChild(fill);
        node.appendChild(bar);
    }
}

function providerVisibility() {
    const provider = els.setLlmProvider.value;
    toggle(els.llmKeyDeepseek, provider === "deepseek");
    toggle(els.llmKeyOpenai, provider === "openai");
    toggle(els.llmKeyGemini, provider === "gemini");
    toggle(els.llmLocalSection, provider === "local");
}

function renderModels(result) {
    const list = els.llmModelList;
    if (!list) return;
    list.textContent = "";

    const models = (result && result.models) || [];
    if (models.length === 0) {
        const empty = document.createElement("div");
        empty.className = "model-empty";
        empty.textContent =
            "Chưa có model .gguf nào. Hãy tải model hoặc chép tệp vào thư mục trên.";
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
            setStatus(`Đang chuyển sang model ${model.name}…`);
            if (els.llmModelList) {
                Array.from(els.llmModelList.children).forEach((child) =>
                    child.classList.remove("active"),
                );
            }
            row.classList.add("active");
            activePath = model.path;
            native.setActiveModel(model.path);
        });

        list.appendChild(row);
    }
}

// ---------------------------------------------------------------------------
// Callback từ Go
// ---------------------------------------------------------------------------

export function handleSettingsLoaded(result) {
    if (!result || !result.settings) return;
    const settings = result.settings;

    if (els.setLlmProvider)
        els.setLlmProvider.value = settings.provider || "local";
    if (els.setDeepseekKey)
        els.setDeepseekKey.value = settings.deepseek_key || "";
    if (els.setOpenaiKey) els.setOpenaiKey.value = settings.openai_key || "";
    if (els.setGeminiKey) els.setGeminiKey.value = settings.gemini_key || "";

    if (els.setModelDir) els.setModelDir.value = settings.model_dir || "";
    activePath = settings.model_path || "";

    const temperature = Number(settings.temperature);
    if (els.setTemperature) {
        els.setTemperature.value = String(
            Number.isFinite(temperature) ? temperature : 0.7,
        );
    }
    if (els.setTempValue) {
        els.setTempValue.textContent = els.setTemperature
            ? els.setTemperature.value
            : "0.7";
    }

    if (els.setContextSize && settings.context_size) {
        els.setContextSize.value = String(settings.context_size);
    }
    if (els.setGpuLayers && settings.gpu_layers != null) {
        els.setGpuLayers.value = String(settings.gpu_layers);
    }

    providerVisibility();
}

export function handleSettingsSaved(result) {
    if (!result) return;
    if (result.ok) {
        setStatus(result.message || "Đã lưu thiết lập.", "ok");
    } else {
        setStatus(result.message || "Không lưu được thiết lập.", "error");
    }
}

export function handleModelsListed(result) {
    if (!result) return;
    if (result.dir && els.setModelDir) els.setModelDir.value = result.dir;
    if (result.active) activePath = result.active;
    renderModels(result);
}

export function handleModelDownloadProgress(progress) {
    if (!progress) return;
    setDownloadStatus(
        `Đang tải ${progress.name}: ${progress.text} (${progress.percent}%)`,
        progress.percent,
    );
}

export function handleModelDownloaded(result) {
    if (!result) return;
    setDownloadStatus(`✅ Đã tải xong ${result.name} (${result.text}).`, 100);
    native.listModels();
}

export function handleModelDownloadError(result) {
    if (!result) return;
    setDownloadStatus(result.message || "Tải model thất bại.");
    setStatus(result.message || "Tải model thất bại.", "error");
    if (els.btnLlmDownload) els.btnLlmDownload.disabled = false;
}

export function handleActiveModelSet(result) {
    if (!result) return;
    if (result.ok) {
        setStatus(result.message || "Đã chọn model.", "ok");
    } else {
        setStatus(result.message || "Không đổi được model.", "error");
    }
    native.listModels();
}

export function handleLLMTestResult(result) {
    if (!result) return;
    setStatus(result.message || "", result.ok ? "ok" : "error");
}

export function handleAIRestarted(result) {
    if (!result) return;
    setStatus(result.message || "", result.ok ? "ok" : "error");
}

// ---------------------------------------------------------------------------
// Hành động
// ---------------------------------------------------------------------------

function openModal() {
    setStatus("");
    setDownloadStatus("");
    show(els.llmSettingsModal);
    native.getSettings();
    native.listModels();
}

function downloadModel() {
    const url = (els.setModelUrl.value || "").trim();
    if (!url) {
        setStatus("Hãy dán URL file .gguf cần tải.", "error");
        return;
    }

    const name = url.split("/").pop().split("?")[0] || "model.gguf";
    if (els.btnLlmDownload) els.btnLlmDownload.disabled = true;
    setDownloadStatus(`Bắt đầu tải ${name}…`, 0);
    native.downloadModel(url, name);
}

function saveSettings() {
    const payload = {
        provider: els.setLlmProvider.value,
        deepseek_key: els.setDeepseekKey.value.trim(),
        openai_key: els.setOpenaiKey.value.trim(),
        gemini_key: els.setGeminiKey.value.trim(),
        temperature: parseFloat(els.setTemperature.value),
        context_size: parseInt(els.setContextSize.value, 10),
        gpu_layers: parseInt(els.setGpuLayers.value, 10),
    };

    if (Number.isNaN(payload.temperature)) payload.temperature = 0.7;
    if (Number.isNaN(payload.context_size)) payload.context_size = 4096;
    if (Number.isNaN(payload.gpu_layers)) payload.gpu_layers = 99;

    setStatus("Đang lưu thiết lập…");
    native.saveSettings(payload);
}

/** Mở bảng thiết lập LLM từ bên ngoài (menu GNOME Shell, IPC...). */
export function openLlmSettings() {
    openModal();
}

// ---------------------------------------------------------------------------
// Khởi tạo
// ---------------------------------------------------------------------------

export function initLlmSettings() {
    els.btnCloseLlmSettings.addEventListener("click", () => {
        hide(els.llmSettingsModal);
    });

    els.setLlmProvider.addEventListener("change", providerVisibility);

    els.setTemperature.addEventListener("input", () => {
        if (els.setTempValue)
            els.setTempValue.textContent = els.setTemperature.value;
    });

    els.btnLlmRefreshModels.addEventListener("click", () =>
        native.listModels(),
    );
    els.btnLlmDownload.addEventListener("click", downloadModel);
    els.btnSaveLlmSettings.addEventListener("click", saveSettings);
    els.btnLlmTest.addEventListener("click", () => {
        setStatus("Đang kiểm tra kết nối…");
        native.testLLM();
    });
    els.btnLlmRestart.addEventListener("click", () => {
        setStatus("Đang khởi động lại AI…");
        native.restartAI();
    });

    providerVisibility();
}
