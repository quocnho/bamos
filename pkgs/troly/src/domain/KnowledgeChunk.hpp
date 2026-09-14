#pragma once

#include <string>

namespace troly::domain {

struct KnowledgeChunk {
    std::string id;
    std::string source;
    std::string title;
    std::string domain;
    std::string content;
    double score{0.0};
    double ftsScore{0.0};
    double vecScore{0.0};
};

} // namespace troly::domain
