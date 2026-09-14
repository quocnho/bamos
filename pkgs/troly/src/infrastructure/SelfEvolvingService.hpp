#pragma once

#include <string>
#include <vector>
#include <memory>
#include <fstream>
#include <filesystem>
#include <iostream>
#include "../domain/GoldenInteraction.hpp"

namespace troly::infrastructure {

struct TrainingStatus {
    int totalGoldenSamples{42};
    int trainedSamples{0};
    int pendingSamples{42};
    std::string lastTrainedDate{"Chưa huấn luyện"};
    std::string currentStatus{"Sẵn sàng (Idle)"};
    double currentLoss{0.0};
    int currentEpoch{0};
    bool isTrainingActive{false};
};

class SelfEvolvingService {
public:
    SelfEvolvingService() {
        populateInitialGoldenData();
    }

    [[nodiscard]] TrainingStatus getStatus() const {
        return m_status;
    }

    [[nodiscard]] const std::vector<domain::GoldenInteraction>& getSamples() const {
        return m_samples;
    }

    bool addGoldenSample(const std::string& prompt, const std::string& response, const std::string& tag = "nixos") {
        domain::GoldenInteraction item;
        item.id = "gold-" + std::to_string(m_samples.size() + 1);
        item.userPrompt = prompt;
        item.assistantResponse = response;
        item.domainTag = tag;
        item.qualityScore = 1.0;
        item.isTrained = false;
        m_samples.push_back(item);

        m_status.totalGoldenSamples = static_cast<int>(m_samples.size());
        m_status.pendingSamples++;
        return true;
    }

    bool exportChatMLDataset(const std::string& outputPath) const {
        std::error_code ec;
        auto parentPath = std::filesystem::path(outputPath).parent_path();
        if (!parentPath.empty() && !std::filesystem::exists(parentPath, ec)) {
            std::filesystem::create_directories(parentPath, ec);
        }

        std::ofstream outFile(outputPath);
        if (!outFile.is_open()) return false;

        for (const auto& sample : m_samples) {
            outFile << sample.toChatML() << "\n";
        }
        return true;
    }

    std::string generateFinetuneCommand(const std::string& baseModelPath, const std::string& dataPath, const std::string& loraOutPath) const {
        return "llama-finetune --model-base " + baseModelPath +
               " --train-data " + dataPath +
               " --lora-out " + loraOutPath +
               " --threads 4 --adam-iter 120 --batch 4 --ctx 2048 --lora-r 16";
    }

    std::string generateMergeCommand(const std::string& baseModelPath, const std::string& loraPath, const std::string& mergedOutPath) const {
        return "llama-export-lora -m " + baseModelPath + " -o " + mergedOutPath + " --lora " + loraPath;
    }

    std::string generateQuantizeCommand(const std::string& mergedModelPath, const std::string& quantOutPath) const {
        return "llama-quantize " + mergedModelPath + " " + quantOutPath + " Q4_K_M";
    }

    void simulateTrainingStep() {
        m_status.isTrainingActive = true;
        m_status.currentStatus = "Đang tối ưu LoRA trọng số...";
        m_status.currentEpoch = 1;
        m_status.currentLoss = 0.428;
    }

    void completeTraining() {
        m_status.isTrainingActive = false;
        m_status.trainedSamples = m_status.totalGoldenSamples;
        m_status.pendingSamples = 0;
        m_status.lastTrainedDate = "2026-09-14 (Phiên bản v01.07)";
        m_status.currentStatus = "Đã cập nhật Adapter mới thành công!";
        for (auto& s : m_samples) {
            s.isTrained = true;
        }
    }

private:
    void populateInitialGoldenData() {
        m_samples = {
            {"gold-1", "Lệnh kiểm tra các dịch vụ lỗi trên NixOS là gì?", "Bạn có thể chạy lệnh: systemctl --failed --plain --no-legend", "nixos", 1.0, false},
            {"gold-2", "Cách dọn dẹp Nix Store an toàn?", "Dùng lệnh: nix-collect-garbage -d để xóa các thế hệ cũ và tối ưu dung lượng đĩa.", "nixos", 1.0, false},
            {"gold-3", "Quy tắc RAII trong C++20 là gì?", "RAII (Resource Acquisition Is Initialization) ràng buộc vòng đời tài nguyên vào vòng đời đối tượng thông qua destructor hoặc std::unique_ptr.", "code", 1.0, false},
            {"gold-4", "Làm sao để switch cấu hình trong BamOS?", "Chạy lệnh: bam switch (hoặc nixos-rebuild switch --flake /etc/nixos#desktop).", "nixos", 1.0, false}
        };
        m_status.totalGoldenSamples = static_cast<int>(m_samples.size());
        m_status.pendingSamples = m_status.totalGoldenSamples;
    }

    std::vector<domain::GoldenInteraction> m_samples;
    TrainingStatus m_status;
};

} // namespace troly::infrastructure
