#include <cassert>
#include <iostream>
#include <string>
#include <vector>
#include "../src/domain/Intent.hpp"
#include "../src/infrastructure/FastHeuristicIntentClassifier.hpp"
#include "../src/infrastructure/DynamicMoERouter.hpp"
#include "../src/infrastructure/LlamaInferenceEngine.hpp"

using namespace troly::domain;
using namespace troly::infrastructure;

void testFastHeuristicIntentClassifier() {
    std::cout << "[TEST] Running testFastHeuristicIntentClassifier...\n";
    FastHeuristicIntentClassifier classifier;

    // Test General Chat
    assert(classifier.classify("Chào em cún cưng nha!") == UserIntent::GeneralChat);
    assert(classifier.classify("Thời tiết hôm nay thế nào?") == UserIntent::GeneralChat);

    // Test Code Generation
    assert(classifier.classify("Hãy viết cho tôi một class C++ quản lý luồng") == UserIntent::CodeGeneration);
    assert(classifier.classify("Hàm python này bị lỗi bug gì vậy?") == UserIntent::CodeGeneration);

    // Test System Command
    assert(classifier.classify("Kiểm tra ram và cpu trên máy tính NixOS") == UserIntent::SystemCommand);
    assert(classifier.classify("Chạy lệnh bam switch cập nhật hệ thống") == UserIntent::SystemCommand);

    // Test Knowledge Query
    assert(classifier.classify("Tra cứu tài liệu quy chuẩn Git trong dự án") == UserIntent::KnowledgeQuery);
    assert(classifier.classify("Tìm kiếm thông tin trong file hướng dẫn") == UserIntent::KnowledgeQuery);

    std::cout << " -> Passed testFastHeuristicIntentClassifier!\n";
}

void testDynamicMoERouter() {
    std::cout << "[TEST] Running testDynamicMoERouter...\n";
    auto classifier = std::make_shared<FastHeuristicIntentClassifier>();
    DynamicMoERouter router(classifier);

    assert(router.availableSlots().size() == 4);

    // Test routing and slot selection
    auto intentCode = router.routeIntent("Viết hàm tính fibonacci bằng C++");
    assert(intentCode == UserIntent::CodeGeneration);
    auto slotCode = router.selectModelForIntent(intentCode);
    assert(slotCode.modelId == "qwen2.5-coder-7b");

    auto intentSys = router.routeIntent("Lệnh systemctl restart display-manager");
    assert(intentSys == UserIntent::SystemCommand);
    auto slotSys = router.selectModelForIntent(intentSys);
    assert(slotSys.modelId == "llama3.2-3b-sys");

    // Test VRAM Budget Supervisor
    assert(router.checkVRAMBudget(slotCode.estimatedVRAMMB, 6000) == true);
    assert(router.checkVRAMBudget(7500, 6000) == false);

    std::cout << " -> Passed testDynamicMoERouter!\n";
}

void testLlamaInferenceEngineMockStream() {
    std::cout << "[TEST] Running testLlamaInferenceEngineMockStream...\n";
    LlamaInferenceEngine engine("http://127.0.0.1:9090");
    assert(engine.isReady());

    ChatMessage msg;
    msg.id = "1";
    msg.role = MessageRole::User;
    msg.content = "Xin chào Troly!";

    std::vector<ChatMessage> history = { msg };

    std::string receivedTokens;
    bool completed = false;

    engine.streamChat(
        history,
        0.7f,
        [&receivedTokens](const std::string& token) {
            receivedTokens += token;
        },
        [&completed](const std::string& full) {
            completed = true;
        },
        [](const std::string& err) {
            std::cerr << "Inference error: " << err << "\n";
        }
    );

    // Đợi streaming hoàn tất tối đa 2000ms
    int waitMs = 0;
    while (!completed && waitMs < 2000) {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        waitMs += 50;
    }
    assert(!receivedTokens.empty());
    assert(completed == true);

    std::cout << " -> Passed testLlamaInferenceEngineMockStream!\n";
}

int main() {
    std::cout << "========================================\n";
    std::cout << "🧪 Troly Inference & MoE Router Test Suite\n";
    std::cout << "========================================\n";

    testFastHeuristicIntentClassifier();
    testDynamicMoERouter();
    testLlamaInferenceEngineMockStream();

    std::cout << "========================================\n";
    std::cout << "✅ ALL INFERENCE & MOE TESTS PASSED 100%\n";
    std::cout << "========================================\n";
    return 0;
}
