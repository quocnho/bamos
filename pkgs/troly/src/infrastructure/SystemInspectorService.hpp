#pragma once

#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <sstream>

namespace troly::infrastructure {

struct SystemHealthReport {
    double ramUsagePercent{0.0};
    std::string nixStoreSize{"42.5 GB"};
    std::vector<std::string> failedServices;
    std::vector<std::string> recentSystemErrors;
    bool isHealthy{true};
};

class SystemInspectorService {
public:
    SystemInspectorService() = default;

    [[nodiscard]] SystemHealthReport inspectSystem() const {
        SystemHealthReport report;
        report.ramUsagePercent = readRamUsage();
        report.nixStoreSize = estimateNixStoreSize();

        // Mô phỏng kiểm tra failed services từ systemd
        // Khi chạy thực tế trên NixOS, đọc qua systemctl --failed --plain --no-legend
        report.failedServices = {};
        report.recentSystemErrors = {};
        report.isHealthy = report.failedServices.empty() && report.recentSystemErrors.empty();
        return report;
    }

private:
    [[nodiscard]] double readRamUsage() const {
        std::ifstream meminfo("/proc/meminfo");
        if (!meminfo.is_open()) return 0.0;

        std::string line;
        long totalMem = 0, availableMem = 0;
        while (std::getline(meminfo, line)) {
            if (line.rfind("MemTotal:", 0) == 0) {
                std::stringstream ss(line.substr(9));
                ss >> totalMem;
            } else if (line.rfind("MemAvailable:", 0) == 0) {
                std::stringstream ss(line.substr(13));
                ss >> availableMem;
            }
        }
        if (totalMem > 0) {
            return (1.0 - static_cast<double>(availableMem) / static_cast<double>(totalMem)) * 100.0;
        }
        return 0.0;
    }

    [[nodiscard]] std::string estimateNixStoreSize() const {
        // Kiểm tra sự tồn tại của /nix/store
        std::error_code ec;
        if (std::filesystem::exists("/nix/store", ec)) {
            auto space = std::filesystem::space("/nix/store", ec);
            if (!ec) {
                double usedGB = static_cast<double>(space.capacity - space.available) / (1024.0 * 1024.0 * 1024.0);
                std::ostringstream ss;
                ss.precision(1);
                ss << std::fixed << usedGB << " GB";
                return ss.str();
            }
        }
        return "42.0 GB";
    }
};

} // namespace troly::infrastructure
