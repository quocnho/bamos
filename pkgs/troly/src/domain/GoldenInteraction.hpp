#pragma once

#include <string>
#include <vector>
#include <sstream>

namespace troly::domain {

struct GoldenInteraction {
    std::string id;
    std::string userPrompt;
    std::string assistantResponse;
    std::string domainTag; // "code", "chat", "nixos", "sys"
    double qualityScore{1.0};
    bool isTrained{false};

    [[nodiscard]] std::string toChatML() const {
        std::ostringstream ss;
        ss << "<|im_start|>system\n"
           << "Bạn là Trợ lý ảo BamOS ('troly'), chuyên gia hệ thống NixOS và lập trình C++20.\n"
           << "<|im_end|>\n"
           << "<|im_start|>user\n"
           << userPrompt << "\n"
           << "<|im_end|>\n"
           << "<|im_start|>assistant\n"
           << assistantResponse << "\n"
           << "<|im_end|>\n";
        return ss.str();
    }
};

} // namespace troly::domain
