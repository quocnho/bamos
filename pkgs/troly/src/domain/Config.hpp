#pragma once

#include <string>
#include <cstdint>

namespace troly::domain {

struct Config {
    std::string provider{"local"}; // "local", "deepseek", "openai", "gemini"
    std::string deepseekKey;
    std::string openaiKey;
    std::string geminiKey;

    // llama-server local runtime
    std::string llamaHost{"http://127.0.0.1:9090"};
    std::string modelDir{"/var/lib/bamos/models"};
    std::string modelPath{"/var/lib/bamos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"};
    int32_t contextSize{4096};
    int32_t gpuLayers{99};
    float temperature{0.7f};

    // RAG Hybrid Search
    bool enableRAG{true};
    std::string ragDbPath{"/var/lib/bamos/rag/knowledge.db"};
    int32_t ragTopK{4};
    float ragHybridAlpha{0.65f}; // 0.0 (FTS only) -> 1.0 (Vector only)

    // GUI & Behaviors
    std::string addressing{"Chủ nhân"};
    bool alwaysOnTop{true};
    std::string themeStyle{"default"};
    bool eyeLeoActive{true};
    int32_t shortBreakIntervalMinutes{20};
    int32_t longBreakIntervalMinutes{60};
};

} // namespace troly::domain
