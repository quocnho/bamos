#pragma once

#include "../domain/ChatMessage.hpp"
#include <string>
#include <vector>
#include <functional>
#include <stop_token>

namespace troly::usecases {

using TokenStreamCallback = std::function<void(const std::string& token)>;

class IInferenceEngine {
public:
    virtual ~IInferenceEngine() = default;

    virtual bool isReady() const = 0;
    virtual void streamChat(
        const std::vector<domain::ChatMessage>& messages,
        float temperature,
        TokenStreamCallback onToken,
        std::function<void(const std::string& fullResponse)> onComplete,
        std::function<void(const std::string& error)> onError,
        std::stop_token stopToken = {}
    ) = 0;

    virtual void abort() = 0;
};

} // namespace troly::usecases
