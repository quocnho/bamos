#include <cassert>
#include <iostream>
#include <filesystem>
#include "../src/infrastructure/SqliteRAGRepository.hpp"

using namespace troly::infrastructure;

void test_rag_initialization_and_ddl() {
    std::string testDbPath = "/tmp/test_troly_rag.db";
    if (std::filesystem::exists(testDbPath)) {
        std::filesystem::remove(testDbPath);
    }

    SqliteRAGRepository repo;
    bool ok = repo.initialize(testDbPath);
    assert(ok == true);
    std::cout << "✅ test_rag_initialization_and_ddl passed! vecLoaded=" << repo.isVecLoaded() << "\n";
}

void test_rag_indexing_and_mock_embedding() {
    std::string testDbPath = "/tmp/test_troly_rag.db";
    SqliteRAGRepository repo;
    repo.initialize(testDbPath);

    // Kiểm tra mock embedding generator
    auto vec1 = SqliteRAGRepository::generateMockEmbedding("NixOS Flake Configuration", 384);
    auto vec2 = SqliteRAGRepository::generateMockEmbedding("NixOS Flake Configuration", 384);
    assert(vec1.size() == 384);
    assert(vec1[0] == vec2[0]); // Tính nhất quán (Deterministic)

    // Chèn tài liệu tri thức
    bool idx1 = repo.indexDocument(
        "nixos_guide",
        "Hướng Dẫn Quản Trị NixOS",
        "system",
        "NixOS sử dụng Flake và BamOS CLI để quản lý gói cấu hình khai báo."
    );
    assert(idx1 == true);

    bool idx2 = repo.indexDocument(
        "cpp20_guide",
        "Lập Trình Clean Architecture C++20",
        "coding",
        "Clean Architecture chia nhỏ domain entities và usecase interfaces để tối ưu token."
    );
    assert(idx2 == true);

    std::cout << "✅ test_rag_indexing_and_mock_embedding passed!\n";
}

void test_rag_hybrid_rrf_search() {
    std::string testDbPath = "/tmp/test_troly_rag.db";
    SqliteRAGRepository repo;
    repo.initialize(testDbPath);

    // Tìm kiếm với từ khóa "NixOS"
    auto results = repo.searchHybrid("NixOS", 5, 0.5f);
    assert(!results.empty());
    assert(results[0].title == "Hướng Dẫn Quản Trị NixOS");
    assert(results[0].score > 0.0);

    // Tìm kiếm với từ khóa "Architecture"
    auto resultsArch = repo.searchHybrid("Architecture", 5, 0.5f);
    assert(!resultsArch.empty());
    assert(resultsArch[0].title == "Lập Trình Clean Architecture C++20");

    std::cout << "✅ test_rag_hybrid_rrf_search passed! (Top score: " << results[0].score << ")\n";

    // Dọn dẹp test database
    if (std::filesystem::exists(testDbPath)) {
        std::filesystem::remove(testDbPath);
    }
}

int main(int argc, char* argv[]) {
    std::cout << "==================================================\n";
    std::cout << "🧪 Running Hybrid RAG & sqlite-vec CTest Unit Tests...\n";
    std::cout << "==================================================\n";

    test_rag_initialization_and_ddl();
    test_rag_indexing_and_mock_embedding();
    test_rag_hybrid_rrf_search();

    std::cout << "🎉 All Hybrid RAG tests passed successfully!\n";
    return 0;
}
