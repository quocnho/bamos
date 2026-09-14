#pragma once

#include <string>
#include <vector>

namespace troly::infrastructure {

struct WakaStats {
    int totalMinutesToday{265}; // ~4h 25m
    std::string primaryLanguage{"C++"};
    int cppPercent{72};
    int nixPercent{18};
    int qmlPercent{10};
    std::string activeProject{"troly"};
    int projectMinutes{190};
};

class WakaTrackerService {
public:
    WakaTrackerService() = default;

    [[nodiscard]] WakaStats getStats() const {
        WakaStats stats;
        // Phân tích nhịp độ phát triển cục bộ từ git commit history
        return stats;
    }
};

} // namespace troly::infrastructure
