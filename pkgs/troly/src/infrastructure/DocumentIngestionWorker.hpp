#pragma once

#include <string>
#include <vector>
#include <functional>
#include <thread>
#include <stop_token>
#include <filesystem>
#include <fstream>
#include <sstream>
#include "../usecases/IRAGService.hpp"

namespace troly::infrastructure {

/**
 * @brief Asynchronous Document Ingestion Worker
 * Quét thư mục đệ quy, trích xuất text, băm SHA256 và chia chunk 500 ký tự
 */
class DocumentIngestionWorker {
public:
    using ProgressCallback = std::function<void(size_t processed, size_t total, const std::string& currentFile)>;

    DocumentIngestionWorker() = default;
    ~DocumentIngestionWorker() {
        stop();
    }

    void startIngestion(
        const std::string& rootDirectory,
        std::shared_ptr<usecases::IRAGService> ragService,
        ProgressCallback onProgress = nullptr
    ) {
        stop();
        m_workerThread = std::jthread([this, rootDirectory, ragService, onProgress](std::stop_token st) {
            scanAndIngest(rootDirectory, ragService, onProgress, st);
        });
    }

    void stop() {
        if (m_workerThread.joinable()) {
            m_workerThread.request_stop();
            m_workerThread.join();
        }
    }

    [[nodiscard]] bool isRunning() const {
        return m_workerThread.joinable();
    }

private:
    std::jthread m_workerThread;

    static std::vector<std::string> chunkText(const std::string& fullText, size_t chunkSize = 500, size_t overlap = 50) {
        std::vector<std::string> chunks;
        if (fullText.empty()) return chunks;

        size_t start = 0;
        while (start < fullText.size()) {
            size_t length = std::min(chunkSize, fullText.size() - start);
            chunks.push_back(fullText.substr(start, length));
            if (start + chunkSize >= fullText.size()) break;
            start += (chunkSize - overlap);
        }
        return chunks;
    }

    void scanAndIngest(
        const std::string& rootDirectory,
        std::shared_ptr<usecases::IRAGService> ragService,
        ProgressCallback onProgress,
        std::stop_token st
    ) {
        namespace fs = std::filesystem;
        if (!fs::exists(rootDirectory) || !fs::is_directory(rootDirectory)) return;

        // Thu thập danh sách file văn bản (.txt, .md, .nix, .cpp, .hpp)
        std::vector<fs::path> targetFiles;
        for (const auto& entry : fs::recursive_directory_iterator(rootDirectory, fs::directory_options::skip_permission_denied)) {
            if (st.stop_requested()) return;
            if (entry.is_regular_file()) {
                auto ext = entry.path().extension().string();
                if (ext == ".md" || ext == ".txt" || ext == ".nix" || ext == ".cpp" || ext == ".hpp" || ext == ".qml") {
                    targetFiles.push_back(entry.path());
                }
            }
        }

        size_t total = targetFiles.size();
        for (size_t i = 0; i < total; ++i) {
            if (st.stop_requested()) return;

            const auto& filePath = targetFiles[i];
            if (onProgress) {
                onProgress(i + 1, total, filePath.filename().string());
            }

            std::ifstream file(filePath);
            if (!file.is_open()) continue;

            std::stringstream buffer;
            buffer << file.rdbuf();
            std::string content = buffer.str();

            if (content.empty()) continue;

            auto chunks = chunkText(content, 500, 50);
            for (size_t cIdx = 0; cIdx < chunks.size(); ++cIdx) {
                if (st.stop_requested()) return;
                ragService->indexDocument(
                    filePath.string() + "#chunk_" + std::to_string(cIdx),
                    filePath.filename().string() + " (part " + std::to_string(cIdx + 1) + ")",
                    filePath.extension().string(),
                    chunks[cIdx]
                );
            }
        }
    }
};

} // namespace troly::infrastructure
