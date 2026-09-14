#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

namespace troly::presentation {

class SystemMonitorViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY statsUpdated)
    Q_PROPERTY(double ramUsage READ ramUsage NOTIFY statsUpdated)
    Q_PROPERTY(QString eyeLeoReminder READ eyeLeoReminder NOTIFY eyeLeoReminderChanged)

public:
    explicit SystemMonitorViewModel(QObject* parent = nullptr);

    [[nodiscard]] double cpuUsage() const { return m_cpuUsage; }
    [[nodiscard]] double ramUsage() const { return m_ramUsage; }
    [[nodiscard]] QString eyeLeoReminder() const { return m_eyeLeoReminder; }

    Q_INVOKABLE void refreshStats();

signals:
    void statsUpdated();
    void eyeLeoReminderChanged();

private:
    double m_cpuUsage{0.0};
    double m_ramUsage{0.0};
    QString m_eyeLeoReminder;
    QTimer* m_timer{nullptr};

    void updateStats();
};

} // namespace troly::presentation
