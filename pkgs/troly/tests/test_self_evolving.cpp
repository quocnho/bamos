#include <cassert>
#include <iostream>
#include <filesystem>
#include "infrastructure/SelfEvolvingService.hpp"

using namespace troly;

void testGoldenInteractions() {
    std::cout << "[TEST] Running SelfEvolvingService Golden Harvesting tests...\n";
    infrastructure::SelfEvolvingService service;
    
    auto status = service.getStatus();
    assert(status.totalGoldenSamples >= 4);
    assert(status.pendingSamples >= 4);
    assert(!status.isTrainingActive);

    // Thêm tương tác vàng mới
    service.addGoldenSample("Làm sao để build troly bằng flake?", "Chạy lệnh: nix build .#troly", "nixos");
    auto newStatus = service.getStatus();
    assert(newStatus.totalGoldenSamples == status.totalGoldenSamples + 1);

    // Kiểm tra xuất ChatML
    std::string exportPath = "/tmp/test_troly_chatml.txt";
    bool ok = service.exportChatMLDataset(exportPath);
    assert(ok);
    assert(std::filesystem::exists(exportPath));
    assert(std::filesystem::file_size(exportPath) > 0);

    // Dọn dẹp tệp test
    std::filesystem::remove(exportPath);
    std::cout << "  Total golden samples: " << newStatus.totalGoldenSamples << "\n";
    std::cout << "  Export ChatML: SUCCESS\n";
    std::cout << "[PASS] Golden Harvesting tests passed!\n";
}

void testCommandGeneration() {
    std::cout << "[TEST] Running SelfEvolvingService Command Generation tests...\n";
    infrastructure::SelfEvolvingService service;

    auto finetuneCmd = service.generateFinetuneCommand("model.gguf", "data.txt", "adapter.bin");
    assert(finetuneCmd.find("llama-finetune") != std::string::npos);
    assert(finetuneCmd.find("--model-base model.gguf") != std::string::npos);
    assert(finetuneCmd.find("--train-data data.txt") != std::string::npos);
    assert(finetuneCmd.find("--lora-out adapter.bin") != std::string::npos);

    auto mergeCmd = service.generateMergeCommand("base.gguf", "lora.bin", "merged.gguf");
    assert(mergeCmd.find("llama-export-lora") != std::string::npos);

    auto quantCmd = service.generateQuantizeCommand("merged.gguf", "quant.gguf");
    assert(quantCmd.find("llama-quantize") != std::string::npos);
    assert(quantCmd.find("Q4_K_M") != std::string::npos);

    std::cout << "  Generated Finetune: " << finetuneCmd << "\n";
    std::cout << "  Generated Merge: " << mergeCmd << "\n";
    std::cout << "  Generated Quantize: " << quantCmd << "\n";
    std::cout << "[PASS] Command Generation tests passed!\n";
}

void testTrainingCycle() {
    std::cout << "[TEST] Running SelfEvolvingService Training Cycle tests...\n";
    infrastructure::SelfEvolvingService service;

    service.simulateTrainingStep();
    auto activeStatus = service.getStatus();
    assert(activeStatus.isTrainingActive);
    assert(activeStatus.currentEpoch == 1);
    assert(activeStatus.currentLoss > 0.0);

    service.completeTraining();
    auto doneStatus = service.getStatus();
    assert(!doneStatus.isTrainingActive);
    assert(doneStatus.pendingSamples == 0);
    assert(doneStatus.trainedSamples == doneStatus.totalGoldenSamples);

    std::cout << "  Completed training cycle with 0 pending samples.\n";
    std::cout << "[PASS] Training Cycle tests passed!\n";
}

int main() {
    testGoldenInteractions();
    testCommandGeneration();
    testTrainingCycle();
    std::cout << "All Self-Evolving Hub tests passed successfully!\n";
    return 0;
}
