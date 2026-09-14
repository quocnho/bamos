#pragma once

#include "../domain/Intent.hpp"
#include "../domain/ModelSlot.hpp"
#include "../usecases/IIntentClassifier.hpp"
#include <memory>
#include <vector>
#include <string>
#include <mutex>

namespace troly::infrastructure {

class DynamicMoERouter {
public:
    explicit DynamicMoERouter(std::shared_ptr<usecases::IIntentClassifier> classifier)
        : m_classifier(std::move(classifier)) {
        initializeDefaultSlots();
    }

    void initializeDefaultSlots() {
        m_slots = {
            {"qwen2.5-3b-chat", "Qwen2.5-3B-Instruct (General)", "qwen2.5-3b-instruct-q4_k_m.gguf", domain::UserIntent::GeneralChat, 4096, 33, 2400},
            {"qwen2.5-coder-7b", "Qwen2.5-Coder-7B (Expert Code)", "qwen2.5-coder-7b-q4_k_m.gguf", domain::UserIntent::CodeGeneration, 8192, 28, 4800},
            {"llama3.2-3b-sys", "Llama-3.2-3B (Linux/SysAdmin)", "llama-3.2-3b-instruct-q4_k_m.gguf", domain::UserIntent::SystemCommand, 4096, 33, 2400},
            {"qwen2.5-3b-rag", "Qwen2.5-3B-Instruct (Knowledge RAG)", "qwen2.5-3b-instruct-q4_k_m.gguf", domain::UserIntent::KnowledgeQuery, 8192, 33, 2800}
        };
        m_activeSlot = m_slots[0];
    }

    [[nodiscard]] domain::UserIntent routeIntent(const std::string& query) {
        if (!m_classifier) return domain::UserIntent::GeneralChat;
        return m_classifier->classify(query);
    }

    [[nodiscard]] domain::ModelSlot selectModelForIntent(domain::UserIntent intent) {
        std::lock_guard<std::mutex> lock(m_mutex);
        for (const auto& slot : m_slots) {
            if (slot.targetIntent == intent) {
                m_activeSlot = slot;
                return slot;
            }
        }
        return m_activeSlot;
    }

    [[nodiscard]] domain::ModelSlot activeModel() const {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_activeSlot;
    }

    [[nodiscard]] const std::vector<domain::ModelSlot>& availableSlots() const {
        return m_slots;
    }

    /// Giám sát ngân sách VRAM tối đa (< 6000MB)
    [[nodiscard]] bool checkVRAMBudget(size_t requiredMB, size_t maxBudgetMB = 6000) const {
        return requiredMB <= maxBudgetMB;
    }

private:
    std::shared_ptr<usecases::IIntentClassifier> m_classifier;
    std::vector<domain::ModelSlot> m_slots;
    domain::ModelSlot m_activeSlot;
    mutable std::mutex m_mutex;
};

} // namespace troly::infrastructure
