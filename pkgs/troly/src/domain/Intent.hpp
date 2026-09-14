#pragma once

#include <string>
#include <string_view>

namespace troly::domain {

enum class UserIntent {
    GeneralChat,    // Hội thoại thông thường, chào hỏi, tâm sự
    CodeGeneration, // Viết code, debug, giải thích giải thuật
    SystemCommand,  // Kiểm tra hệ thống, lệnh Linux/NixOS, cấu hình
    KnowledgeQuery  // Tra cứu tài liệu, kiến thức RAG, tìm kiếm file
};

inline std::string_view userIntentToString(UserIntent intent) {
    switch (intent) {
        case UserIntent::GeneralChat:    return "GeneralChat";
        case UserIntent::CodeGeneration: return "CodeGeneration";
        case UserIntent::SystemCommand:  return "SystemCommand";
        case UserIntent::KnowledgeQuery: return "KnowledgeQuery";
    }
    return "GeneralChat";
}

} // namespace troly::domain
