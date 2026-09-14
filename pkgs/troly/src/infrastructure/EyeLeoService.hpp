#pragma once

#include <QObject>
#include <QTimer>
#include <cstdint>
#include "../usecases/IEyeLeoService.hpp"
#include "../domain/EyeLeoConfig.hpp"

namespace troly::infrastructure {

/**
 * @brief Hiện thực dịch vụ bảo vệ mắt EyeLeo Native C++
 * Quản lý nhịp đếm làm việc, phát hiện máy nghỉ (Mutter D-Bus) và phát tín hiệu tới UI
 */
class EyeLeoService : public QObject, public usecases::IEyeLeoService {
    Q_OBJECT

public:
    explicit EyeLeoService(QObject* parent = nullptr);
    ~EyeLeoService() override;

    void start() override;
    void stop() override;
    void updateConfig(const domain::EyeLeoConfig& config) override;
    [[nodiscard]] domain::EyeLeoConfig getConfig() const override { return m_config; }

    void skipBreak() override;
    void postponeLongBreak(int32_t extraSec) override;
    void triggerShortBreakNow() override;
    void triggerLongBreakNow() override;

    [[nodiscard]] int32_t getWorkSeconds() const override { return m_workSeconds; }
    [[nodiscard]] domain::EyeLeoBreakType getActiveBreak() const override { return m_activeBreak; }

signals:
    void prebreakWarningTriggered(int32_t secondsLeft);
    void shortBreakTriggered(int32_t durationSec);
    void longBreakTriggered(int32_t durationSec, bool isStrict);
    void breakFinished();
    void workCycleReset();
    void tickSecond(int32_t workSec, int32_t countdownSec);

private slots:
    void onTick();
    void checkMutterIdleTime();

private:
    domain::EyeLeoConfig m_config;
    QTimer* m_secondTimer{nullptr};
    QTimer* m_idleCheckTimer{nullptr};

    int32_t m_workSeconds{0};
    int32_t m_lastShortBreakAt{0};
    int32_t m_lastLongBreakAt{0};
    bool m_prebreakFired{false};

    domain::EyeLeoBreakType m_activeBreak{domain::EyeLeoBreakType::None};
    int32_t m_breakCountdown{0};

    int64_t queryMutterIdleTimeMs();
    void endCurrentBreak();
};

} // namespace troly::infrastructure
