// ============================================================================
// features/profile-ui.js — Giao diện Hồ sơ người dùng (Slim)
// ============================================================================

import { els, show, hide, toggle } from "../core/dom.js";
import { native } from "../core/native.js";
import { handleQuizQuestions, submitQuiz, renderRoadmap } from "./profile/quiz-ui.js";

export { handleQuizQuestions };

const ADDRESSING_PRESETS = ["Chủ nhân", "Anh", "Chị", "Ông", "Bà", "Bạn"];
let selectedDomains = [];
let availableDomainsList = [
    "Công nghệ thông tin & Phát triển phần mềm",
    "Dữ liệu & Trí tuệ nhân tạo (AI / Data)",
    "Kỹ thuật & Tự động hóa (Cơ khí, Điện tử, Xây dựng...)",
    "Sản xuất & Vận hành chuỗi cung ứng (Manufacturing / Supply Chain)",
    "Marketing, Truyền thông & Quan hệ công chúng (PR)",
    "Bán hàng & Phát triển kinh doanh (Sales / BD)",
    "Tài chính, Kế toán & Kiểm toán",
    "Nhân sự, Tuyển dụng & Đào tạo nội bộ (HR)",
    "Thiết kế, Nghệ thuật & Sáng tạo nội dung (UI/UX, Đồ họa, Video...)",
    "Pháp chế & Tuân thủ (Legal & Compliance)",
    "Y tế, Dược phẩm & Chăm sóc sức khỏe",
    "Giáo dục, Giảng dạy & Nghiên cứu (R&D)",
    "Quản trị & Điều hành chung (C-Level, Founder, Quản lý tổng quát)",
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
    [els.tabProfileInfo, els.tabProfileQuiz, els.tabProfileRoadmap].forEach(t => { if (t) t.style.background = "#f1f5f9"; });

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

    fillProfileAddressing(p.addressing || "Chủ nhân");
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
        chip.addEventListener("click", () => {
            const idx = selectedDomains.indexOf(domain);
            if (idx >= 0) selectedDomains.splice(idx, 1);
            else if (selectedDomains.length < 3) selectedDomains.push(domain);
            renderDomainChips();
        });
        container.appendChild(chip);
    });
}

export function handleQuizSubmitted(result) {
    if (!result || !result.ok) return;
    alert(`🎉 Hoàn thành bài test! Điểm: ${result.score}/${result.total}\nTrình độ được xếp: ${result.level}`);
    if (els.profCurrentLevel) els.profCurrentLevel.textContent = result.level;
    renderRoadmap(result.roadmap || []);
    switchTab("roadmap");
}

function saveProfile() {
    const profile = {
        full_name: els.profFullname ? els.profFullname.value.trim() : "",
        age: els.profAge ? parseInt(els.profAge.value, 10) || 0 : 0,
        phone: els.profPhone ? els.profPhone.value.trim() : "",
        email: els.profEmail ? els.profEmail.value.trim() : "",
        addressing: getSelectedAddressing(),
        domains: selectedDomains.slice(0, 3),
        preferences: { theme_color: els.profThemeColor ? els.profThemeColor.value : "teal" },
    };
    native.updateProfile(profile);
    if (els.profileStatus) {
        els.profileStatus.textContent = "Đã lưu hồ sơ thành công!";
        els.profileStatus.style.color = "#2a9d8f";
        setTimeout(() => { if (els.profileStatus) els.profileStatus.textContent = ""; }, 3000);
    }
}

export function initProfileUI() {
    if (els.btnCloseProfile) els.btnCloseProfile.addEventListener("click", () => hide(els.profileModal));
    if (els.tabProfileInfo) els.tabProfileInfo.addEventListener("click", () => switchTab("info"));
    if (els.tabProfileQuiz) els.tabProfileQuiz.addEventListener("click", () => switchTab("quiz"));
    if (els.tabProfileRoadmap) els.tabProfileRoadmap.addEventListener("click", () => switchTab("roadmap"));
    if (els.btnSaveProfile) els.btnSaveProfile.addEventListener("click", saveProfile);
    if (els.btnSubmitQuiz) els.btnSubmitQuiz.addEventListener("click", submitQuiz);
    if (els.profAddressing) {
        els.profAddressing.addEventListener("change", () => {
            const isCustom = els.profAddressing.value === "__custom__";
            toggle(els.profAddressingCustom, isCustom);
            if (isCustom && els.profAddressingCustom) els.profAddressingCustom.focus();
        });
    }
}
