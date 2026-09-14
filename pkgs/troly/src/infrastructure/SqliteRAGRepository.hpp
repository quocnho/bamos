#pragma once

#include "../usecases/IRAGService.hpp"
#include <sqlite3.h>
#include <memory>
#include <mutex>
#include <vector>

namespace troly::infrastructure {

/**
 * @brief Hiện thực kho lưu trữ tri thức Hybrid RAG với SQLite WAL, FTS5 và sqlite-vec
 */
class SqliteRAGRepository : public usecases::IRAGService {
public:
    SqliteRAGRepository();
    ~SqliteRAGRepository() override;

    bool initialize(const std::string& dbPath) override;

    std::vector<domain::KnowledgeChunk> searchHybrid(
        const std::string& query,
        int32_t topK,
        float alpha,
        std::stop_token stopToken = {}
    ) override;

    bool indexDocument(
        const std::string& source,
        const std::string& title,
        const std::string& domain,
        const std::string& content
    ) override;

    // Bổ sung hỗ trợ chèn embedding trực tiếp cho Sprint 03
    bool indexChunkWithEmbedding(
        const std::string& chunkId,
        const std::string& source,
        const std::string& title,
        const std::string& domain,
        const std::string& content,
        const std::vector<float>& embedding
    );

    // Mock Embedding Generator 384 chiều phục vụ test và air-gapped POC
    static std::vector<float> generateMockEmbedding(const std::string& text, size_t dimensions = 384);

    [[nodiscard]] bool isVecLoaded() const { return m_vecLoaded; }

private:
    std::mutex m_mutex;
    sqlite3* m_db{nullptr};
    std::string m_dbPath;
    bool m_vecLoaded{false};

    bool initSchema();
    bool loadVecExtension();
};

} // namespace troly::infrastructure
