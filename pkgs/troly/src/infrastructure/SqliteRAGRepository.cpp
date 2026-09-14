#include "SqliteRAGRepository.hpp"
#include <iostream>
#include <sstream>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <unordered_map>
#include <algorithm>

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
    
    // Ưu tiên đường dẫn từ biến môi trường SQLITE_VEC_PATH (NixOS)
    const char* envPath = std::getenv("SQLITE_VEC_PATH");
    const char* vecLibPath = (envPath && envPath[0] != '\0') ? envPath : "vec0";

    int rc = sqlite3_load_extension(m_db, vecLibPath, "sqlite3_vec_init", &errMsg);
    if (rc != SQLITE_OK) {
        // Nếu load bằng đường dẫn cụ thể thất bại, thử lại với "vec0" mặc định
        if (envPath) {
            if (errMsg) { sqlite3_free(errMsg); errMsg = nullptr; }
            rc = sqlite3_load_extension(m_db, "vec0", "sqlite3_vec_init", &errMsg);
        }
    }

    if (rc != SQLITE_OK) {
        std::cerr << "[SqliteRAG] Warning: Could not load vec0 extension (" 
                  << (errMsg ? errMsg : "unknown") << "). Falling back to FTS5 only.\n";
        if (errMsg) sqlite3_free(errMsg);
        m_vecLoaded = false;
        return false;
    }
    std::cout << "[SqliteRAG] Successfully loaded sqlite-vec extension from: " << vecLibPath << "\n";
    m_vecLoaded = true;
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

    // DDL chuẩn phân rã: collections, documents, doc_chunks, chunks_fts
    const char* schemaSql = 
        "CREATE TABLE IF NOT EXISTS collections ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  name TEXT NOT NULL UNIQUE,"
        "  base_path TEXT NOT NULL,"
        "  created_at INTEGER NOT NULL"
        ");"
        "CREATE TABLE IF NOT EXISTS documents ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  collection_id INTEGER,"
        "  file_path TEXT NOT NULL UNIQUE,"
        "  file_hash TEXT NOT NULL,"
        "  updated_at INTEGER NOT NULL"
        ");"
        "CREATE TABLE IF NOT EXISTS doc_chunks ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  chunk_uid TEXT UNIQUE NOT NULL,"
        "  document_id INTEGER,"
        "  source TEXT NOT NULL,"
        "  title TEXT NOT NULL,"
        "  domain TEXT NOT NULL,"
        "  content TEXT NOT NULL,"
        "  created_at INTEGER NOT NULL"
        ");"
        "CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5("
        "  chunk_uid UNINDEXED, title, domain, content, tokenize='porter unicode61'"
        ");";

    if (sqlite3_exec(m_db, schemaSql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
        std::cerr << "[SqliteRAG] Failed to init standard schema: " << (errMsg ? errMsg : "") << "\n";
        if (errMsg) sqlite3_free(errMsg);
        return false;
    }

    // Nếu sqlite-vec nạp thành công, tạo virtual table vec_chunks với 384 dimensions
    if (m_vecLoaded) {
        const char* vecSql = 
            "CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0("
            "  chunk_id INTEGER PRIMARY KEY,"
            "  embedding FLOAT[384]"
            ");";
        if (sqlite3_exec(m_db, vecSql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
            std::cerr << "[SqliteRAG] Warning: Failed to init vec_chunks: " << (errMsg ? errMsg : "") << "\n";
            if (errMsg) sqlite3_free(errMsg);
        } else {
            std::cout << "[SqliteRAG] Initialized virtual table vec_chunks (FLOAT[384])\n";
        }
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

std::vector<float> SqliteRAGRepository::generateMockEmbedding(const std::string& text, size_t dimensions) {
    // Thuật toán hashing vector giả lập chuẩn hóa L2 norm 384 chiều
    std::vector<float> vec(dimensions, 0.0f);
    if (text.empty()) return vec;

    uint32_t hash = 5381;
    for (char c : text) {
        hash = ((hash << 5) + hash) + static_cast<uint8_t>(c);
    }

    float norm = 0.0f;
    for (size_t i = 0; i < dimensions; ++i) {
        hash = (hash * 1103515245 + 12345) & 0x7fffffff;
        float val = static_cast<float>(hash % 1000) / 500.0f - 1.0f;
        vec[i] = val;
        norm += val * val;
    }

    norm = std::sqrt(norm);
    if (norm > 0.0001f) {
        for (size_t i = 0; i < dimensions; ++i) {
            vec[i] /= norm;
        }
    }

    return vec;
}

bool SqliteRAGRepository::indexChunkWithEmbedding(
    const std::string& chunkId,
    const std::string& source,
    const std::string& title,
    const std::string& domain,
    const std::string& content,
    const std::vector<float>& embedding
) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_db) return false;

    // 1. Chèn vào doc_chunks
    const char* sql = 
        "INSERT INTO doc_chunks (chunk_uid, source, title, domain, content, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?);";

    sqlite3_stmt* stmt = nullptr;
    if (sqlite3_prepare_v2(m_db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return false;
    }

    sqlite3_bind_text(stmt, 1, chunkId.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, source.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, title.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4, domain.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5, content.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(stmt, 6, static_cast<sqlite3_int64>(std::time(nullptr)));

    if (sqlite3_step(stmt) != SQLITE_DONE) {
        sqlite3_finalize(stmt);
        return false;
    }

    sqlite3_int64 rowId = sqlite3_last_insert_rowid(m_db);
    sqlite3_finalize(stmt);

    // 2. Chèn vào chunks_fts
    const char* ftsSql = "INSERT INTO chunks_fts (chunk_uid, title, domain, content) VALUES (?, ?, ?, ?);";
    sqlite3_stmt* ftsStmt = nullptr;
    if (sqlite3_prepare_v2(m_db, ftsSql, -1, &ftsStmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(ftsStmt, 1, chunkId.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(ftsStmt, 2, title.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(ftsStmt, 3, domain.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(ftsStmt, 4, content.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_step(ftsStmt);
        sqlite3_finalize(ftsStmt);
    }

    // 3. Nếu vec_chunks khả dụng và có embedding, chèn vào vec_chunks
    if (m_vecLoaded && embedding.size() == 384) {
        const char* vecSql = "INSERT INTO vec_chunks (chunk_id, embedding) VALUES (?, ?);";
        sqlite3_stmt* vecStmt = nullptr;
        if (sqlite3_prepare_v2(m_db, vecSql, -1, &vecStmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int64(vecStmt, 1, rowId);
            sqlite3_bind_blob(vecStmt, 2, embedding.data(), static_cast<int>(embedding.size() * sizeof(float)), SQLITE_TRANSIENT);
            sqlite3_step(vecStmt);
            sqlite3_finalize(vecStmt);
        }
    }

    return true;
}

bool SqliteRAGRepository::indexDocument(
    const std::string& source,
    const std::string& title,
    const std::string& domain,
    const std::string& content
) {
    std::string chunkId = source + "_" + std::to_string(std::time(nullptr));
    std::vector<float> mockVec = generateMockEmbedding(content, 384);
    return indexChunkWithEmbedding(chunkId, source, title, domain, content, mockVec);
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

    // Cấu trúc bảng điểm RRF: chunk_uid -> {KnowledgeChunk, ftsRank, vecRank}
    struct RRFEntry {
        domain::KnowledgeChunk chunk;
        int ftsRank{0};
        int vecRank{0};
        double rrfScore{0.0};
    };
    std::unordered_map<std::string, RRFEntry> rrfMap;

    // 1. Thực thi tìm kiếm từ khóa FTS5 BM25
    const char* ftsSql = 
        "SELECT d.chunk_uid, d.title, d.domain, d.content, bm25(chunks_fts) as rank "
        "FROM chunks_fts f "
        "JOIN doc_chunks d ON f.chunk_uid = d.chunk_uid "
        "WHERE chunks_fts MATCH ? "
        "ORDER BY rank ASC "
        "LIMIT ?;";

    sqlite3_stmt* ftsStmt = nullptr;
    if (sqlite3_prepare_v2(m_db, ftsSql, -1, &ftsStmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(ftsStmt, 1, query.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(ftsStmt, 2, topK * 2);

        int rankIdx = 1;
        while (sqlite3_step(ftsStmt) == SQLITE_ROW) {
            if (stopToken.stop_requested()) break;

            std::string uid = reinterpret_cast<const char*>(sqlite3_column_text(ftsStmt, 0));
            auto& entry = rrfMap[uid];
            entry.chunk.id = uid;
            entry.chunk.title = reinterpret_cast<const char*>(sqlite3_column_text(ftsStmt, 1));
            entry.chunk.domain = reinterpret_cast<const char*>(sqlite3_column_text(ftsStmt, 2));
            entry.chunk.content = reinterpret_cast<const char*>(sqlite3_column_text(ftsStmt, 3));
            entry.chunk.ftsScore = sqlite3_column_double(ftsStmt, 4);
            entry.ftsRank = rankIdx++;
        }
        sqlite3_finalize(ftsStmt);
    }

    // 2. Thực thi tìm kiếm ngữ nghĩa vector sqlite-vec (nếu có)
    if (m_vecLoaded) {
        std::vector<float> qVec = generateMockEmbedding(query, 384);
        const char* vecSql = 
            "SELECT d.chunk_uid, d.title, d.domain, d.content, v.distance "
            "FROM vec_chunks v "
            "JOIN doc_chunks d ON v.chunk_id = d.id "
            "WHERE embedding MATCH ? "
            "ORDER BY distance ASC "
            "LIMIT ?;";

        sqlite3_stmt* vecStmt = nullptr;
        if (sqlite3_prepare_v2(m_db, vecSql, -1, &vecStmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_blob(vecStmt, 1, qVec.data(), static_cast<int>(qVec.size() * sizeof(float)), SQLITE_TRANSIENT);
            sqlite3_bind_int(vecStmt, 2, topK * 2);

            int rankIdx = 1;
            while (sqlite3_step(vecStmt) == SQLITE_ROW) {
                if (stopToken.stop_requested()) break;

                std::string uid = reinterpret_cast<const char*>(sqlite3_column_text(vecStmt, 0));
                auto& entry = rrfMap[uid];
                if (entry.chunk.id.empty()) {
                    entry.chunk.id = uid;
                    entry.chunk.title = reinterpret_cast<const char*>(sqlite3_column_text(vecStmt, 1));
                    entry.chunk.domain = reinterpret_cast<const char*>(sqlite3_column_text(vecStmt, 2));
                    entry.chunk.content = reinterpret_cast<const char*>(sqlite3_column_text(vecStmt, 3));
                }
                entry.chunk.vecScore = sqlite3_column_double(vecStmt, 4);
                entry.vecRank = rankIdx++;
            }
            sqlite3_finalize(vecStmt);
        }
    }

    // 3. Tính toán Reciprocal Rank Fusion (RRF): Score = 1 / (60 + r_fts) + 1 / (60 + r_vec)
    const double k = 60.0;
    std::vector<RRFEntry> sortedEntries;
    sortedEntries.reserve(rrfMap.size());

    for (auto& [uid, entry] : rrfMap) {
        double ftsScore = (entry.ftsRank > 0) ? (1.0 / (k + entry.ftsRank)) : 0.0;
        double vecScore = (entry.vecRank > 0) ? (1.0 / (k + entry.vecRank)) : 0.0;
        // Kết hợp với tham số alpha (trọng số giữa FTS và Vector)
        entry.rrfScore = (1.0f - alpha) * ftsScore + alpha * vecScore;
        entry.chunk.score = entry.rrfScore;
        sortedEntries.push_back(std::move(entry));
    }

    // Sắp xếp theo điểm RRF giảm dần
    std::sort(sortedEntries.begin(), sortedEntries.end(), [](const RRFEntry& a, const RRFEntry& b) {
        return a.rrfScore > b.rrfScore;
    });

    // Trích xuất Top K kết quả
    size_t count = std::min(static_cast<size_t>(topK), sortedEntries.size());
    results.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        results.push_back(std::move(sortedEntries[i].chunk));
    }

    return results;
}

} // namespace troly::infrastructure
