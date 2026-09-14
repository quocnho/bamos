#include "SystemMonitorViewModel.hpp"
#include <fstream>
#include <sstream>

namespace troly::presentation {

SystemMonitorViewModel::SystemMonitorViewModel(QObject* parent)
    : QObject(parent)
    , m_timer(new QTimer(this)) {
    connect(m_timer, &QTimer::timeout, this, &SystemMonitorViewModel::refreshStats);
    m_timer->start(3000); // 3 giây cập nhật một lần
    refreshStats();
}

void SystemMonitorViewModel::refreshStats() {
    updateStats();
    emit statsUpdated();
}

void SystemMonitorViewModel::updateStats() {
    // Đọc thông tin RAM từ /proc/meminfo của Linux
    std::ifstream meminfo("/proc/meminfo");
    if (meminfo.is_open()) {
        std::string line;
        long totalMem = 0, freeMem = 0, availableMem = 0;
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
            m_ramUsage = (1.0 - static_cast<double>(availableMem) / static_cast<double>(totalMem)) * 100.0;
        }
    }
}

} // namespace troly::presentation
