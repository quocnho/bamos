// ============================================================================
// features/profile/quiz-ui.js — Giao diện câu hỏi trắc nghiệm & lộ trình
// ============================================================================

import { els } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { escapeHtml } from "../../core/utils.js";

export let currentQuestions = [];

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

export function submitQuiz() {
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

export function renderRoadmap(steps) {
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
