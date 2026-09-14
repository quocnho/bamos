#pragma once

#include "../usecases/IIntentClassifier.hpp"
#include <algorithm>
#include <regex>

namespace troly::infrastructure {

class FastHeuristicIntentClassifier : public usecases::IIntentClassifier {
public:
    domain::UserIntent classify(const std::string& text) override {
        if (text.empty()) {
            return domain::UserIntent::GeneralChat;
        }

        std::string lowerText = text;
        std::transform(lowerText.begin(), lowerText.end(), lowerText.begin(), ::tolower);

        // 1. Kiểm tra ý định System Command / NixOS
        if (lowerText.find("nixos") != std::string::npos ||
            lowerText.find("systemctl") != std::string::npos ||
            lowerText.find("journalctl") != std::string::npos ||
            lowerText.find("bam switch") != std::string::npos ||
            lowerText.find("nix-build") != std::string::npos ||
            lowerText.find("nix build") != std::string::npos ||
            lowerText.find("ram") != std::string::npos ||
            lowerText.find("cpu") != std::string::npos ||
            lowerText.find("disk") != std::string::npos ||
            lowerText.find("dung lượng") != std::string::npos ||
            lowerText.find("tiến trình") != std::string::npos ||
            lowerText.find("system") != std::string::npos) {
            return domain::UserIntent::SystemCommand;
        }

        // 2. Kiểm tra ý định Lập trình / Viết Code
        if (lowerText.find("code") != std::string::npos ||
            lowerText.find("lập trình") != std::string::npos ||
            lowerText.find("c++") != std::string::npos ||
            lowerText.find("python") != std::string::npos ||
            lowerText.find("rust") != std::string::npos ||
            lowerText.find("javascript") != std::string::npos ||
            lowerText.find("function") != std::string::npos ||
            lowerText.find("class ") != std::string::npos ||
            lowerText.find("struct ") != std::string::npos ||
            lowerText.find("cmake") != std::string::npos ||
            lowerText.find("bug") != std::string::npos ||
            lowerText.find("refactor") != std::string::npos ||
            lowerText.find("debug") != std::string::npos ||
            lowerText.find("void ") != std::string::npos ||
            lowerText.find("int main") != std::string::npos) {
            return domain::UserIntent::CodeGeneration;
        }

        // 3. Kiểm tra ý định Tra cứu Tài liệu / Tri thức (RAG)
        if (lowerText.find("tài liệu") != std::string::npos ||
            lowerText.find("tra cứu") != std::string::npos ||
            lowerText.find("tìm kiếm") != std::string::npos ||
            lowerText.find("hồ sơ") != std::string::npos ||
            lowerText.find("quy chuẩn") != std::string::npos ||
            lowerText.find("tóm tắt file") != std::string::npos ||
            lowerText.find("trong file") != std::string::npos ||
            lowerText.find("đọc file") != std::string::npos ||
            lowerText.find("kiến thức") != std::string::npos) {
            return domain::UserIntent::KnowledgeQuery;
        }

        return domain::UserIntent::GeneralChat;
    }
};

} // namespace troly::infrastructure
