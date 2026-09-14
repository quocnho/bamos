#pragma once

#include "../domain/KnowledgeChunk.hpp"
#include <string>
#include <vector>
#include <stop_token>

namespace troly::usecases {

class IRAGService {
public:
    virtual ~IRAGService() = default;

    virtual bool initialize(const std::string& dbPath) = 0;
    virtual std::vector<domain::KnowledgeChunk> searchHybrid(
        const std::string& query,
        int32_t topK,
        float alpha,
        std::stop_token stopToken = {}
    ) = 0;

    virtual bool indexDocument(
        const std::string& source,
        const std::string& title,
        const std::string& domain,
        const std::string& content
    ) = 0;
};

} // namespace troly::usecases
