#include "EyeLeoService.hpp"
#include <QProcess>
#include <QRegularExpression>
#include <iostream>

namespace troly::infrastructure {

EyeLeoService::EyeLeoService(QObject* parent)
    : QObject(parent)
{
    m_secondTimer = new QTimer(this);
    m_secondTimer->setInterval(1000);
    connect(m_secondTimer, &QTimer::timeout, this, &EyeLeoService::onTick);

    m_idleCheckTimer = new QTimer(this);
    m_idleCheckTimer->setInterval(15000); // 15s kiểm tra idle 1 lần
    connect(m_idleCheckTimer, &QTimer::timeout, this, &EyeLeoService::checkMutterIdleTime);
}

EyeLeoService::~EyeLeoService() {
    stop();
}

void EyeLeoService::start() {
    if (!m_config.enabled) return;
    m_secondTimer->start();
    m_idleCheckTimer->start();
}

void EyeLeoService::stop() {
    m_secondTimer->stop();
    m_idleCheckTimer->stop();
    m_activeBreak = domain::EyeLeoBreakType::None;
    m_breakCountdown = 0;
}

void EyeLeoService::updateConfig(const domain::EyeLeoConfig& config) {
    m_config = config;
    if (!m_config.enabled) {
        stop();
    } else if (!m_secondTimer->isActive()) {
        start();
    }
}

void EyeLeoService::skipBreak() {
    if (m_activeBreak == domain::EyeLeoBreakType::LongBreak && m_config.strictMode) {
        return; // Không cho phép bỏ qua nếu đang ở Strict Mode
    }
    endCurrentBreak();
}

void EyeLeoService::postponeLongBreak(int32_t extraSec) {
    if (m_activeBreak != domain::EyeLeoBreakType::None) {
        endCurrentBreak();
    }
    // Hoãn lại bằng cách lùi thời gian đếm chu kỳ nghỉ dài
    m_lastLongBreakAt = m_workSeconds - (m_config.longBreakIntervalSec - extraSec);
    m_prebreakFired = false;
}

void EyeLeoService::triggerShortBreakNow() {
    m_activeBreak = domain::EyeLeoBreakType::ShortBreak;
    m_breakCountdown = m_config.shortBreakDurationSec;
    emit shortBreakTriggered(m_breakCountdown);
}

void EyeLeoService::triggerLongBreakNow() {
    m_activeBreak = domain::EyeLeoBreakType::LongBreak;
    m_breakCountdown = m_config.longBreakDurationSec;
    emit longBreakTriggered(m_breakCountdown, m_config.strictMode);
}

void EyeLeoService::endCurrentBreak() {
    m_activeBreak = domain::EyeLeoBreakType::None;
    m_breakCountdown = 0;
    emit breakFinished();
}

void EyeLeoService::onTick() {
    if (!m_config.enabled) return;

    if (m_activeBreak != domain::EyeLeoBreakType::None) {
        m_breakCountdown--;
        emit tickSecond(m_workSeconds, m_breakCountdown);
        if (m_breakCountdown <= 0) {
            endCurrentBreak();
        }
        return;
    }

    m_workSeconds++;
    emit tickSecond(m_workSeconds, 0);

    const int32_t timeSinceLong = m_workSeconds - m_lastLongBreakAt;
    const int32_t timeSinceShort = m_workSeconds - m_lastShortBreakAt;

    // 1. Kiểm tra cảnh báo trước 30s khi sắp nghỉ dài
    if (m_config.prebreakWarningSec > 0 &&
        timeSinceLong >= (m_config.longBreakIntervalSec - m_config.prebreakWarningSec) &&
        !m_prebreakFired)
    {
        m_prebreakFired = true;
        emit prebreakWarningTriggered(m_config.longBreakIntervalSec - timeSinceLong);
    }

    // 2. Kích hoạt nghỉ dài (Long Break)
    if (timeSinceLong >= m_config.longBreakIntervalSec) {
        m_lastLongBreakAt = m_workSeconds;
        m_lastShortBreakAt = m_workSeconds;
        m_prebreakFired = false;
        triggerLongBreakNow();
        return;
    }

    // 3. Kích hoạt nghỉ ngắn (Short Break)
    if (timeSinceShort >= m_config.shortBreakIntervalSec) {
        m_lastShortBreakAt = m_workSeconds;
        triggerShortBreakNow();
    }
}

int64_t EyeLeoService::queryMutterIdleTimeMs() {
    // Gọi gdbus Mutter IdleMonitor để đo thời gian người dùng không tương tác chuột/phím
    QProcess proc;
    proc.start("gdbus", {
        "call", "--session",
        "--dest", "org.gnome.Mutter.IdleMonitor",
        "--object-path", "/org/gnome/Mutter/IdleMonitor/Core",
        "--method", "org.gnome.Mutter.IdleMonitor.GetIdletime"
    });

    if (!proc.waitForFinished(1000)) {
        proc.kill();
        return 0;
    }

    QString out = proc.readAllStandardOutput().trimmed();
    // Kết quả dạng: (uint64 12345,)
    static QRegularExpression re(R"(\(uint64\s+(\d+),?\))");
    auto match = re.match(out);
    if (match.hasMatch()) {
        return match.captured(1).toLongLong();
    }
    return 0;
}

void EyeLeoService::checkMutterIdleTime() {
    if (!m_config.autoIdle || m_activeBreak != domain::EyeLeoBreakType::None) return;

    int64_t idleMs = queryMutterIdleTimeMs();
    if (idleMs >= m_config.idleThresholdMs && m_workSeconds > 60) {
        // Đặt lại chu kỳ làm việc do người dùng đã rời máy
        m_workSeconds = 0;
        m_lastShortBreakAt = 0;
        m_lastLongBreakAt = 0;
        m_prebreakFired = false;
        emit workCycleReset();
    }
}

} // namespace troly::infrastructure
