#pragma once

#include <QObject>
#include <QString>
#include <memory>
#include "../infrastructure/EyeLeoService.hpp"

namespace troly::presentation {

/**
 * @brief ViewModel kết nối giữa EyeLeoService và giao diện QML
 */
class EyeLeoViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isBreakActive READ isBreakActive NOTIFY breakStateChanged)
    Q_PROPERTY(QString breakType READ breakType NOTIFY breakStateChanged)
    Q_PROPERTY(int countdownSec READ countdownSec NOTIFY countdownChanged)
    Q_PROPERTY(bool isStrict READ isStrict NOTIFY breakStateChanged)
    Q_PROPERTY(bool isPrebreakActive READ isPrebreakActive NOTIFY prebreakChanged)
    Q_PROPERTY(int workMinutes READ workMinutes NOTIFY workTimeChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY configChanged)
    Q_PROPERTY(bool strictMode READ strictMode WRITE setStrictMode NOTIFY configChanged)

public:
    explicit EyeLeoViewModel(std::shared_ptr<infrastructure::EyeLeoService> service, QObject* parent = nullptr);

    [[nodiscard]] bool isBreakActive() const { return m_isBreakActive; }
    [[nodiscard]] QString breakType() const { return m_breakType; }
    [[nodiscard]] int countdownSec() const { return m_countdownSec; }
    [[nodiscard]] bool isStrict() const { return m_isStrict; }
    [[nodiscard]] bool isPrebreakActive() const { return m_isPrebreakActive; }
    [[nodiscard]] int workMinutes() const { return m_workSeconds / 60; }
    [[nodiscard]] bool enabled() const;
    [[nodiscard]] bool strictMode() const;

    Q_INVOKABLE void setEnabled(bool value);
    Q_INVOKABLE void setStrictMode(bool value);
    Q_INVOKABLE void skipBreak();
    Q_INVOKABLE void postponeLongBreak();
    Q_INVOKABLE void dismissPrebreak();
    Q_INVOKABLE void triggerShortBreak();
    Q_INVOKABLE void triggerLongBreak();

signals:
    void breakStateChanged();
    void countdownChanged();
    void prebreakChanged();
    void workTimeChanged();
    void configChanged();
    void exerciseStepChanged(int stepIndex, const QString& instruction);

private:
    std::shared_ptr<infrastructure::EyeLeoService> m_service;
    bool m_isBreakActive{false};
    QString m_breakType{"none"};
    int m_countdownSec{0};
    bool m_isStrict{false};
    bool m_isPrebreakActive{false};
    int m_workSeconds{0};

    void setupConnections();
};

} // namespace troly::presentation
