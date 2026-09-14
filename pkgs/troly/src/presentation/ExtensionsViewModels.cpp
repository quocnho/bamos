#include "ExtensionsViewModels.hpp"

namespace troly::presentation {

// --- SystemInspectorViewModel ---
SystemInspectorViewModel::SystemInspectorViewModel(
    std::shared_ptr<infrastructure::SystemInspectorService> inspector,
    QObject* parent
)
    : QObject(parent), m_inspector(std::move(inspector)) {
    scanHealth();
}

QString SystemInspectorViewModel::statusSummary() const {
    if (m_report.isHealthy) {
        return "Hệ thống hoạt động hoàn hảo, không có dịch vụ lỗi.";
    }
    return "Phát hiện một số cảnh báo trong nhật ký hệ thống.";
}

void SystemInspectorViewModel::scanHealth() {
    if (m_inspector) {
        m_report = m_inspector->inspectSystem();
        emit dataChanged();
    }
}

// --- WakaTrackerViewModel ---
WakaTrackerViewModel::WakaTrackerViewModel(
    std::shared_ptr<infrastructure::WakaTrackerService> tracker,
    QObject* parent
)
    : QObject(parent), m_tracker(std::move(tracker)) {
    refreshStats();
}

QString WakaTrackerViewModel::formattedTime() const {
    int hours = m_stats.totalMinutesToday / 60;
    int mins = m_stats.totalMinutesToday % 60;
    return QString("%1 giờ %2 phút").arg(hours).arg(mins);
}

void WakaTrackerViewModel::refreshStats() {
    if (m_tracker) {
        m_stats = m_tracker->getStats();
        emit dataChanged();
    }
}

// --- UserProfileViewModel ---
UserProfileViewModel::UserProfileViewModel(QObject* parent)
    : QObject(parent) {}

void UserProfileViewModel::setUserName(const QString& name) {
    if (userName() != name) {
        m_profile.userName = name.toStdString();
        emit profileChanged();
    }
}

void UserProfileViewModel::setAddressing(const QString& addr) {
    if (addressing() != addr) {
        m_profile.addressing = addr.toStdString();
        emit profileChanged();
    }
}

void UserProfileViewModel::setTechnicalLevel(const QString& lvl) {
    if (technicalLevel() != lvl) {
        m_profile.technicalLevel = lvl.toStdString();
        emit profileChanged();
    }
}

void UserProfileViewModel::saveProfile() {
    emit profileChanged();
}

// --- SelfEvolvingViewModel ---
SelfEvolvingViewModel::SelfEvolvingViewModel(
    std::shared_ptr<infrastructure::SelfEvolvingService> service,
    QObject* parent
)
    : QObject(parent), m_service(std::move(service)) {
    if (m_service) {
        m_status = m_service->getStatus();
    }
}

void SelfEvolvingViewModel::exportDataset(const QString& path) {
    if (m_service) {
        std::string exportPath = path.isEmpty() ? "/tmp/troly_train_data.txt" : path.toStdString();
        bool ok = m_service->exportChatMLDataset(exportPath);
        if (ok) {
            emit datasetExported(QString("Đã xuất %1 mẫu vàng ChatML sang %2")
                                 .arg(m_status.totalGoldenSamples)
                                 .arg(QString::fromStdString(exportPath)));
        } else {
            emit datasetExported("Lỗi: Không thể xuất tệp dữ liệu.");
        }
        m_status = m_service->getStatus();
        emit dataChanged();
    }
}

void SelfEvolvingViewModel::triggerOfflineTraining() {
    if (m_service) {
        m_service->simulateTrainingStep();
        m_status = m_service->getStatus();
        emit dataChanged();

        // Hoàn tất giả lập huấn luyện adapter cục bộ
        m_service->completeTraining();
        m_status = m_service->getStatus();
        emit dataChanged();
    }
}

} // namespace troly::presentation
