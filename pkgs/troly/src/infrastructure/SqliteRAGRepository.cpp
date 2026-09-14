#include "SqliteRAGRepository.hpp"
#include <iostream>
#include <sstream>

namespace troly::infrastructure {

SqliteRAGRepository::SqliteRAGRepository() = default;

SqliteRAGRepository::~SqliteRAGRepository() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_db) {
        sqlite3_close(m_db);
        m_db = nullptr;
    }
}

bool SqliteRAGRepository::loadVecExtension() {
    if (!m_db) return false;
    sqlite3_enable_load_extension(m_db, 1);
    char* errMsg = nullptr;
    // Cố gắng tải vec0 từ standard paths hoặc nix store
    int rc = sqlite3_load_extension(m_db, "vec0", "sqlite3_vec_init", &errMsg);
    if (rc != SQLITE_OK) {
        // Dự phòng đường dẫn trên NixOS nếu có
        std::cerr << "[SqliteRAG] Warning: Could not load vec0 extension directly (" 
                  << (errMsg ? errMsg : "unknown") << "). Falling back to FTS5.\n";
        if (errMsg) sqlite3_free(errMsg);
        return false;
    }
    return true;
}

bool SqliteRAGRepository::initSchema() {
    if (!m_db) return false;

    const char* pragmaSql = 
        "PRAGMA journal_mode = WAL;"
        "PRAGMA synchronous = NORMAL;"
        "PRAGMA foreign_keys = ON;"
        "PRAGMA busy_timeout = 5000;";

    char* errMsg = nullptr;
    if (sqlite3_exec(m_db, pragmaSql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
        std::cerr << "[SqliteRAG] Failed to set WAL pragmas: " << (errMsg ? errMsg : "") << "\n";
        if (errMsg) sqlite3_free(errMsg);
    }

    const char* schemaSql = 
        "CREATE TABLE IF NOT EXISTS knowledge_chunks ("
        "  id TEXT PRIMARY KEY,"
        "  source TEXT,"
        "  title TEXT,"
        "  domain TEXT,"
        "  content TEXT,"
        "  created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5("
        "  id UNINDEXED, title, domain, content, tokenize='porter unicode61'"
        ");";

    if (sqlite3_exec(m_db, schemaSql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
        std::cerr << "[SqliteRAG] Failed to init schema: " << (errMsg ? errMsg : "") << "\n";
        if (errMsg) sqlite3_free(errMsg);
        return false;
    }

    return true;
}

bool SqliteRAGRepository::initialize(const std::string& dbPath) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_dbPath = dbPath;

    int rc = sqlite3_open_v2(
        m_dbPath.c_str(),
        &m_db,
        SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
        nullptr
    );

    if (rc != SQLITE_OK) {
        std::cerr << "[SqliteRAG] Cannot open database at " << m_dbPath << "\n";
        return false;
    }

    loadVecExtension();
    return initSchema();
}

std::vector<domain::KnowledgeChunk> SqliteRAGRepository::searchHybrid(
    const std::string& query,
    int32_t topK,
    float alpha,
    std::stop_token stopToken
) {
    std::lock_guard<std::mutex> lock(m_mutex);
    std::vector<domain::KnowledgeChunk> results;
    if (!m_db || query.empty() || stopToken.stop_requested()) {
        return results;
    }

    // FTS5 BM25 Ranking search
    const char* sql = 
        "SELECT id, title, domain, content, bm25(chunks_fts) as rank "
        "FROM chunks_fts "
        "WHERE chunks_fts MATCH ? "
        "ORDER BY rank "
        "LIMIT ?;";

    sqlite3_stmt* stmt = nullptr;
    if (sqlite3_prepare_v2(m_db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return results;
    }

    sqlite3_bind_text(stmt, 1, query.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 2, topK);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (stopToken.stop_requested()) break;

        domain::KnowledgeChunk chunk;
        chunk.id = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        chunk.title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        chunk.domain = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
        chunk.content = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));
        chunk.ftsScore = sqlite3_column_double(stmt, 4);
        chunk.score = (1.0f - alpha) * static_cast<float>(chunk.ftsScore);

        results.push_back(std::move(chunk));
    }

    sqlite3_finalize(stmt);
    return results;
}

bool SqliteRAGRepository::indexDocument(
    const std::string& source,
    const std::string& title,
    const std::string& domain,
    const std::string& content
) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_db) return false;

    const char* sql = 
        "INSERT INTO knowledge_chunks (id, source, title, domain, content) "
        "VALUES (?, ?, ?, ?, ?);";

    sqlite3_stmt* stmt = nullptr;
    if (sqlite3_prepare_v2(m_db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return false;
    }

    std::string id = source + "_" + std::to_string(std::time(nullptr));
    sqlite3_bind_text(stmt, 1, id.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, source.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, title.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4, domain.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5, content.c_str(), -1, SQLITE_TRANSIENT);

    bool ok = (sqlite3_step(stmt) == SQLITE_DONE);
    sqlite3_finalize(stmt);

    if (ok) {
        const char* ftsSql = "INSERT INTO chunks_fts (id, title, domain, content) VALUES (?, ?, ?, ?);";
        sqlite3_stmt* ftsStmt = nullptr;
        if (sqlite3_prepare_v2(m_db, ftsSql, -1, &ftsStmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(ftsStmt, 1, id.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(ftsStmt, 2, title.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(ftsStmt, 3, domain.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(ftsStmt, 4, content.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(ftsStmt);
            sqlite3_finalize(ftsStmt);
        }
    }

    return ok;
}

} // namespace troly::infrastructure
