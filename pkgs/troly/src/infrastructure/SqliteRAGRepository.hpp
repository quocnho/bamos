#pragma once

#include "../usecases/IRAGService.hpp"
#include <sqlite3.h>
#include <memory>
#include <mutex>

namespace troly::infrastructure {

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

private:
    std::mutex m_mutex;
    sqlite3* m_db{nullptr};
    std::string m_dbPath;

    bool initSchema();
    bool loadVecExtension();
};

} // namespace troly::infrastructure
