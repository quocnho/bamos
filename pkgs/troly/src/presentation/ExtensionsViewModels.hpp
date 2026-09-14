#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <memory>
#include "../infrastructure/SystemInspectorService.hpp"
#include "../infrastructure/WakaTrackerService.hpp"
#include "../domain/UserProfile.hpp"

namespace troly::presentation {

class SystemInspectorViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(double ramUsage READ ramUsage NOTIFY dataChanged)
    Q_PROPERTY(QString nixStoreSize READ nixStoreSize NOTIFY dataChanged)
    Q_PROPERTY(bool isHealthy READ isHealthy NOTIFY dataChanged)
    Q_PROPERTY(QString statusSummary READ statusSummary NOTIFY dataChanged)

public:
    explicit SystemInspectorViewModel(std::shared_ptr<infrastructure::SystemInspectorService> inspector, QObject* parent = nullptr);
    ~SystemInspectorViewModel() override = default;

    [[nodiscard]] double ramUsage() const { return m_report.ramUsagePercent; }
    [[nodiscard]] QString nixStoreSize() const { return QString::fromStdString(m_report.nixStoreSize); }
    [[nodiscard]] bool isHealthy() const { return m_report.isHealthy; }
    [[nodiscard]] QString statusSummary() const;

    Q_INVOKABLE void scanHealth();

signals:
    void dataChanged();

private:
    std::shared_ptr<infrastructure::SystemInspectorService> m_inspector;
    infrastructure::SystemHealthReport m_report;
};

class WakaTrackerViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(int totalMinutesToday READ totalMinutesToday NOTIFY dataChanged)
    Q_PROPERTY(QString formattedTime READ formattedTime NOTIFY dataChanged)
    Q_PROPERTY(QString primaryLanguage READ primaryLanguage NOTIFY dataChanged)
    Q_PROPERTY(int cppPercent READ cppPercent NOTIFY dataChanged)
    Q_PROPERTY(int nixPercent READ nixPercent NOTIFY dataChanged)
    Q_PROPERTY(int qmlPercent READ qmlPercent NOTIFY dataChanged)

public:
    explicit WakaTrackerViewModel(std::shared_ptr<infrastructure::WakaTrackerService> tracker, QObject* parent = nullptr);
    ~WakaTrackerViewModel() override = default;

    [[nodiscard]] int totalMinutesToday() const { return m_stats.totalMinutesToday; }
    [[nodiscard]] QString formattedTime() const;
    [[nodiscard]] QString primaryLanguage() const { return QString::fromStdString(m_stats.primaryLanguage); }
    [[nodiscard]] int cppPercent() const { return m_stats.cppPercent; }
    [[nodiscard]] int nixPercent() const { return m_stats.nixPercent; }
    [[nodiscard]] int qmlPercent() const { return m_stats.qmlPercent; }

    Q_INVOKABLE void refreshStats();

signals:
    void dataChanged();

private:
    std::shared_ptr<infrastructure::WakaTrackerService> m_tracker;
    infrastructure::WakaStats m_stats;
};

class UserProfileViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString userName READ userName WRITE setUserName NOTIFY profileChanged)
    Q_PROPERTY(QString addressing READ addressing WRITE setAddressing NOTIFY profileChanged)
    Q_PROPERTY(QString technicalLevel READ technicalLevel WRITE setTechnicalLevel NOTIFY profileChanged)

public:
    explicit UserProfileViewModel(QObject* parent = nullptr);
    ~UserProfileViewModel() override = default;

    [[nodiscard]] QString userName() const { return QString::fromStdString(m_profile.userName); }
    [[nodiscard]] QString addressing() const { return QString::fromStdString(m_profile.addressing); }
    [[nodiscard]] QString technicalLevel() const { return QString::fromStdString(m_profile.technicalLevel); }
    [[nodiscard]] const domain::UserProfile& profile() const { return m_profile; }

    void setUserName(const QString& name);
    void setAddressing(const QString& addr);
    void setTechnicalLevel(const QString& lvl);

    Q_INVOKABLE void saveProfile();

signals:
    void profileChanged();

private:
    domain::UserProfile m_profile;
};

} // namespace troly::presentation
