#pragma once

#include "../usecases/IInferenceEngine.hpp"
#include <string>
#include <atomic>

namespace troly::infrastructure {

class LlamaInferenceEngine : public usecases::IInferenceEngine {
public:
    explicit LlamaInferenceEngine(std::string hostUrl = "http://127.0.0.1:9090");
    ~LlamaInferenceEngine() override;

    bool isReady() const override;
    void streamChat(
        const std::vector<domain::ChatMessage>& messages,
        float temperature,
        usecases::TokenStreamCallback onToken,
        std::function<void(const std::string& fullResponse)> onComplete,
        std::function<void(const std::string& error)> onError,
        std::stop_token stopToken = {}
    ) override;

    void abort() override;

private:
    std::string m_hostUrl;
    std::atomic<bool> m_abortRequested{false};
};

} // namespace troly::infrastructure
