#include "LlamaInferenceEngine.hpp"
#include <iostream>
#include <thread>

namespace troly::infrastructure {

LlamaInferenceEngine::LlamaInferenceEngine(std::string hostUrl)
    : m_hostUrl(std::move(hostUrl)) {}

LlamaInferenceEngine::~LlamaInferenceEngine() {
    abort();
}

bool LlamaInferenceEngine::isReady() const {
    return !m_hostUrl.empty();
}

void LlamaInferenceEngine::abort() {
    m_abortRequested.store(true);
}

void LlamaInferenceEngine::streamChat(
    const std::vector<domain::ChatMessage>& messages,
    float temperature,
    usecases::TokenStreamCallback onToken,
    std::function<void(const std::string& fullResponse)> onComplete,
    std::function<void(const std::string& error)> onError,
    std::stop_token stopToken
) {
    m_abortRequested.store(false);

    // Chạy bất đồng bộ mô phỏng luồng streaming kết nối llama-server SSE
    std::jthread worker([this, messages, onToken, onComplete, onError, stopToken]() {
        if (messages.empty()) {
            if (onError) onError("Danh sách tin nhắn trống.");
            return;
        }

        std::string mockResponse = "Dạ, em là Trợ lý BamOS. Em đã nhận được yêu cầu từ Chủ nhân và sẵn sàng hỗ trợ trên nền tảng C++20 Qt6 Native!";
        std::string accumulated;

        std::istringstream stream(mockResponse);
        std::string word;
        while (stream >> word) {
            if (stopToken.stop_requested() || m_abortRequested.load()) {
                if (onError) onError("Tác vụ đã bị ngắt bởi người dùng.");
                return;
            }

            std::string token = word + " ";
            accumulated += token;
            if (onToken) {
                onToken(token);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(30));
        }

        if (onComplete) {
            onComplete(accumulated);
        }
    });

    worker.detach();
}

} // namespace troly::infrastructure
