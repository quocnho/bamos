// ============================================================================
// features/settings/llm-settings.js — Bảng thiết lập LLM (Slim)
// ============================================================================

import { els, hide, show, toggle } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { renderModels, activePath, setActivePath } from "./llm-models-ui.js";

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

export function handleSettingsLoaded(result) {
    if (!result || !result.settings) return;
    const settings = result.settings;
    if (els.setLlmProvider) els.setLlmProvider.value = settings.provider || "local";
    if (els.setDeepseekKey) els.setDeepseekKey.value = settings.deepseek_key || "";
    if (els.setOpenaiKey) els.setOpenaiKey.value = settings.openai_key || "";
    if (els.setGeminiKey) els.setGeminiKey.value = settings.gemini_key || "";
    if (els.setModelDir) els.setModelDir.value = settings.model_dir || "";
    setActivePath(settings.model_path || "");

    const temp = Number(settings.temperature);
    if (els.setTemperature) els.setTemperature.value = String(Number.isFinite(temp) ? temp : 0.7);
    if (els.setTempValue) els.setTempValue.textContent = els.setTemperature ? els.setTemperature.value : "0.7";
    if (els.setContextSize && settings.context_size) els.setContextSize.value = String(settings.context_size);
    if (els.setGpuLayers && settings.gpu_layers != null) els.setGpuLayers.value = String(settings.gpu_layers);
    providerVisibility();
}

export function handleSettingsSaved(result) {
    if (!result) return;
    setStatus(result.ok ? (result.message || "Đã lưu thiết lập.") : (result.message || "Không lưu được."), result.ok ? "ok" : "error");
}

export function handleModelsListed(result) {
    if (!result) return;
    if (result.dir && els.setModelDir) els.setModelDir.value = result.dir;
    if (result.active) setActivePath(result.active);
    renderModels(result, (m) => {
        setStatus(`Đang chuyển sang model ${m.name}…`);
        native.setActiveModel(m.path);
    });
}

export function handleModelDownloadProgress(progress) {
    if (!progress) return;
    setDownloadStatus(`Đang tải ${progress.name}: ${progress.text} (${progress.percent}%)`, progress.percent);
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
    setStatus(result.ok ? (result.message || "Đã chọn model.") : (result.message || "Không đổi được model."), result.ok ? "ok" : "error");
    native.listModels();
}

export function handleLLMTestResult(result) {
    if (result) setStatus(result.message || "", result.ok ? "ok" : "error");
}

export function handleAIRestarted(result) {
    if (result) setStatus(result.message || "", result.ok ? "ok" : "error");
}

export function openLlmSettings() {
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
        temperature: parseFloat(els.setTemperature.value) || 0.7,
        context_size: parseInt(els.setContextSize.value, 10) || 4096,
        gpu_layers: parseInt(els.setGpuLayers.value, 10) || 99,
    };
    setStatus("Đang lưu thiết lập…");
    native.saveSettings(payload);
}

export function initLlmSettings() {
    els.btnCloseLlmSettings.addEventListener("click", () => hide(els.llmSettingsModal));
    els.setLlmProvider.addEventListener("change", providerVisibility);
    els.setTemperature.addEventListener("input", () => {
        if (els.setTempValue) els.setTempValue.textContent = els.setTemperature.value;
    });
    els.btnLlmRefreshModels.addEventListener("click", () => native.listModels());
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
