// ============================================================================
// features/profile-ui.js — Giao diện Hồ sơ người dùng & Onboarding Quiz
// ============================================================================

import { els, show, hide, toggle } from "../core/dom.js";
import { native } from "../core/native.js";

const ADDRESSING_PRESETS = ["Chủ nhân", "Anh", "Chị", "Ông", "Bà", "Bạn"];

let currentQuestions = [];
let selectedDomains = [];
let availableDomainsList = [
    "NixOS & Linux System",
    "Lập trình Backend & Go",
    "AI, SLM & RAG Vector Search",
    "Frontend Web & UI/UX Design",
    "DevOps, Docker & Cloud Native",
    "An toàn thông tin & Bảo mật",
    "Khoa học dữ liệu & Data Analytics",
    "Embedded, IoT & Phần cứng",
];

export function openProfileModal() {
    show(els.profileModal);
    switchTab("info");
    native.getProfile();
    native.getQuiz();
}

function switchTab(tab) {
    hide(els.panelProfileInfo);
    hide(els.panelProfileQuiz);
    hide(els.panelProfileRoadmap);

    if (els.tabProfileInfo) els.tabProfileInfo.style.background = "#f1f5f9";
    if (els.tabProfileQuiz) els.tabProfileQuiz.style.background = "#f1f5f9";
    if (els.tabProfileRoadmap) els.tabProfileRoadmap.style.background = "#f1f5f9";

    if (tab === "info") {
        show(els.panelProfileInfo);
        if (els.tabProfileInfo) els.tabProfileInfo.style.background = "#2a9d8f";
    } else if (tab === "quiz") {
        show(els.panelProfileQuiz);
        if (els.tabProfileQuiz) els.tabProfileQuiz.style.background = "#2a9d8f";
    } else if (tab === "roadmap") {
        show(els.panelProfileRoadmap);
        if (els.tabProfileRoadmap) els.tabProfileRoadmap.style.background = "#2a9d8f";
    }
}

export function handleProfileLoaded(result) {
    if (!result || !result.ok || !result.profile) return;
    const p = result.profile;

    if (els.profFullname) els.profFullname.value = p.full_name || "";
    if (els.profAge) els.profAge.value = p.age || "";
    if (els.profPhone) els.profPhone.value = p.phone || "";
    if (els.profEmail) els.profEmail.value = p.email || "";

    // Xử lý xưng hô
    fillProfileAddressing(p.addressing || "Chủ nhân");

    // Xử lý lĩnh vực chuyên môn (tối đa 3)
    if (result.available_domains && Array.isArray(result.available_domains)) {
        availableDomainsList = result.available_domains;
    }
    selectedDomains = Array.isArray(p.domains) ? p.domains.slice(0, 3) : [];
    renderDomainChips();

    if (els.profThemeColor && p.preferences) {
        els.profThemeColor.value = p.preferences.theme_color || "teal";
    }
    if (els.profCurrentLevel) {
        els.profCurrentLevel.textContent = p.current_level || "Chưa đánh giá";
    }
    renderRoadmap(p.roadmap_steps || []);
}

function fillProfileAddressing(val) {
    const addr = (val || "Chủ nhân").trim();
    if (ADDRESSING_PRESETS.includes(addr)) {
        if (els.profAddressing) els.profAddressing.value = addr;
        toggle(els.profAddressingCustom, false);
        if (els.profAddressingCustom) els.profAddressingCustom.value = "";
    } else {
        if (els.profAddressing) els.profAddressing.value = "__custom__";
        toggle(els.profAddressingCustom, true);
        if (els.profAddressingCustom) els.profAddressingCustom.value = addr;
    }
}

function getSelectedAddressing() {
    if (!els.profAddressing) return "Chủ nhân";
    if (els.profAddressing.value === "__custom__") {
        return (els.profAddressingCustom ? els.profAddressingCustom.value : "").trim() || "Chủ nhân";
    }
    return els.profAddressing.value || "Chủ nhân";
}

function renderDomainChips() {
    const container = els.profDomainsContainer;
    if (!container) return;
    container.innerHTML = "";

    availableDomainsList.forEach((domain) => {
        const chip = document.createElement("button");
        chip.type = "button";
        chip.className = "domain-chip" + (selectedDomains.includes(domain) ? " active" : "");
        chip.textContent = domain;
        chip.addEventListener("click", () => toggleDomain(domain));
        container.appendChild(chip);
    });

    updateDomainsCounter();
}

function toggleDomain(domain) {
    const idx = selectedDomains.indexOf(domain);
    if (idx >= 0) {
        selectedDomains.splice(idx, 1);
    } else {
        if (selectedDomains.length >= 3) {
            if (els.profileStatus) {
                els.profileStatus.textContent = "Chỉ được chọn tối đa 3 lĩnh vực quan tâm!";
                els.profileStatus.style.color = "#ef4444";
                setTimeout(() => {
                    if (els.profileStatus) els.profileStatus.textContent = "";
                }, 2500);
            }
            return;
        }
        selectedDomains.push(domain);
    }
    renderDomainChips();
}

function updateDomainsCounter() {
    if (els.profDomainsCounter) {
        els.profDomainsCounter.textContent = `(${selectedDomains.length}/3 lĩnh vực)`;
        if (selectedDomains.length === 3) {
            els.profDomainsCounter.style.color = "#2a9d8f";
        } else {
            els.profDomainsCounter.style.color = "#64748b";
        }
    }
}

export function handleQuizQuestions(result) {
    if (!result || !result.ok) return;
    currentQuestions = result.questions || [];

    const container = els.quizContainer;
    if (!container) return;
    container.innerHTML = "";

    currentQuestions.forEach((q, idx) => {
        const card = document.createElement("div");
        card.style.cssText = "background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; font-size: 12px;";

        let optionsHtml = "";
        q.options.forEach((opt, oIdx) => {
            optionsHtml += `
                <label style="display: flex; align-items: center; gap: 8px; margin: 4px 0; cursor: pointer;">
                    <input type="radio" name="quiz_q_${q.id}" value="${oIdx}" />
                    <span>${escapeHtml(opt)}</span>
                </label>
            `;
        });

        card.innerHTML = `
            <div style="font-weight: 700; color: #1e293b; margin-bottom: 6px;">
                Câu ${idx + 1}: ${escapeHtml(q.question)}
            </div>
            <div>${optionsHtml}</div>
        `;
        container.appendChild(card);
    });
}

function submitQuiz() {
    const answers = {};
    currentQuestions.forEach((q) => {
        const selected = document.querySelector(`input[name="quiz_q_${q.id}"]:checked`);
        if (selected) {
            answers[q.id] = parseInt(selected.value, 10);
        }
    });

    if (Object.keys(answers).length < currentQuestions.length) {
        alert("Vui lòng trả lời hết tất cả các câu hỏi trước khi chấm điểm nhé!");
        return;
    }

    native.submitQuiz(answers);
}

export function handleQuizSubmitted(result) {
    if (!result || !result.ok) return;
    alert(`🎉 Hoàn thành bài test! Điểm: ${result.score}/${result.total}\nTrình độ được xếp: ${result.level}`);
    if (els.profCurrentLevel) {
        els.profCurrentLevel.textContent = result.level;
    }
    renderRoadmap(result.roadmap || []);
    switchTab("roadmap");
}

function renderRoadmap(steps) {
    const list = els.roadmapStepsList;
    if (!list) return;
    list.innerHTML = "";

    if (steps.length === 0) {
        list.innerHTML = `<div class="model-empty">Làm bài test ở tab trên để mở khoá lộ trình cá nhân hoá!</div>`;
        return;
    }

    steps.forEach((step, idx) => {
        const item = document.createElement("div");
        item.style.cssText = "background: #fff; border: 1px solid #e2e8f0; border-left: 4px solid #2a9d8f; border-radius: 6px; padding: 8px 12px; font-size: 12px;";
        item.innerHTML = `
            <div style="font-weight: 700; color: #1e293b;">
                Bước ${idx + 1}: ${escapeHtml(step.title)} [${escapeHtml(step.domain)}]
            </div>
            <div style="font-size: 11.5px; color: #64748b; margin-top: 2px;">
                ${escapeHtml(step.description)}
            </div>
        `;
        list.appendChild(item);
    });
}

function saveProfile() {
    const profile = {
        full_name: els.profFullname ? els.profFullname.value.trim() : "",
        age: els.profAge ? parseInt(els.profAge.value, 10) || 0 : 0,
        phone: els.profPhone ? els.profPhone.value.trim() : "",
        email: els.profEmail ? els.profEmail.value.trim() : "",
        addressing: getSelectedAddressing(),
        domains: selectedDomains.slice(0, 3),
        preferences: {
            theme_color: els.profThemeColor ? els.profThemeColor.value : "teal",
        },
    };
    native.updateProfile(profile);
    if (els.profileStatus) {
        els.profileStatus.textContent = "Đã lưu hồ sơ thành công!";
        els.profileStatus.style.color = "#2a9d8f";
        setTimeout(() => {
            if (els.profileStatus) els.profileStatus.textContent = "";
        }, 3000);
    }
}

function escapeHtml(str) {
    if (!str) return "";
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export function initProfileUI() {
    if (els.btnCloseProfile) {
        els.btnCloseProfile.addEventListener("click", () => hide(els.profileModal));
    }
    if (els.tabProfileInfo) {
        els.tabProfileInfo.addEventListener("click", () => switchTab("info"));
    }
    if (els.tabProfileQuiz) {
        els.tabProfileQuiz.addEventListener("click", () => switchTab("quiz"));
    }
    if (els.tabProfileRoadmap) {
        els.tabProfileRoadmap.addEventListener("click", () => switchTab("roadmap"));
    }
    if (els.btnSaveProfile) {
        els.btnSaveProfile.addEventListener("click", saveProfile);
    }
    if (els.btnSubmitQuiz) {
        els.btnSubmitQuiz.addEventListener("click", submitQuiz);
    }
    if (els.profAddressing) {
        els.profAddressing.addEventListener("change", () => {
            const isCustom = els.profAddressing.value === "__custom__";
            toggle(els.profAddressingCustom, isCustom);
            if (isCustom && els.profAddressingCustom) {
                els.profAddressingCustom.focus();
            }
        });
    }
}
