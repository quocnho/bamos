#pragma once

#include <string>
#include <chrono>

namespace troly::domain {

enum class MessageRole {
    System,
    User,
    Assistant,
    Tool
};

struct ChatMessage {
    std::string id;
    MessageRole role{MessageRole::User};
    std::string content;
    std::chrono::system_clock::time_point timestamp{std::chrono::system_clock::now()};

    [[nodiscard]] std::string roleString() const {
        switch (role) {
            case MessageRole::System: return "system";
            case MessageRole::User: return "user";
            case MessageRole::Assistant: return "assistant";
            case MessageRole::Tool: return "tool";
        }
        return "user";
    }
};

} // namespace troly::domain
