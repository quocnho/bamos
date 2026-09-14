#include "EyeLeoViewModel.hpp"

namespace troly::presentation {

EyeLeoViewModel::EyeLeoViewModel(std::shared_ptr<infrastructure::EyeLeoService> service, QObject* parent)
    : QObject(parent), m_service(std::move(service))
{
    setupConnections();
}

void EyeLeoViewModel::setupConnections() {
    if (!m_service) return;

    connect(m_service.get(), &infrastructure::EyeLeoService::prebreakWarningTriggered, this, [this](int32_t secLeft) {
        m_isPrebreakActive = true;
        m_countdownSec = secLeft;
        emit prebreakChanged();
        emit countdownChanged();
    });

    connect(m_service.get(), &infrastructure::EyeLeoService::shortBreakTriggered, this, [this](int32_t durationSec) {
        m_isPrebreakActive = false;
        m_isBreakActive = true;
        m_breakType = "short";
        m_countdownSec = durationSec;
        m_isStrict = false;
        emit prebreakChanged();
        emit breakStateChanged();
        emit countdownChanged();
    });

    connect(m_service.get(), &infrastructure::EyeLeoService::longBreakTriggered, this, [this](int32_t durationSec, bool strict) {
        m_isPrebreakActive = false;
        m_isBreakActive = true;
        m_breakType = "long";
        m_countdownSec = durationSec;
        m_isStrict = strict;
        emit prebreakChanged();
        emit breakStateChanged();
        emit countdownChanged();
    });

    connect(m_service.get(), &infrastructure::EyeLeoService::breakFinished, this, [this]() {
        m_isBreakActive = false;
        m_breakType = "none";
        m_countdownSec = 0;
        emit breakStateChanged();
        emit countdownChanged();
    });

    connect(m_service.get(), &infrastructure::EyeLeoService::tickSecond, this, [this](int32_t workSec, int32_t cdSec) {
        m_workSeconds = workSec;
        emit workTimeChanged();
        if (m_isBreakActive || m_isPrebreakActive) {
            m_countdownSec = cdSec;
            emit countdownChanged();
        }
    });

    connect(m_service.get(), &infrastructure::EyeLeoService::workCycleReset, this, [this]() {
        m_workSeconds = 0;
        emit workTimeChanged();
    });
}

bool EyeLeoViewModel::enabled() const {
    return m_service ? m_service->getConfig().enabled : false;
}

bool EyeLeoViewModel::strictMode() const {
    return m_service ? m_service->getConfig().strictMode : false;
}

void EyeLeoViewModel::setEnabled(bool value) {
    if (!m_service) return;
    auto cfg = m_service->getConfig();
    if (cfg.enabled != value) {
        cfg.enabled = value;
        m_service->updateConfig(cfg);
        emit configChanged();
    }
}

void EyeLeoViewModel::setStrictMode(bool value) {
    if (!m_service) return;
    auto cfg = m_service->getConfig();
    if (cfg.strictMode != value) {
        cfg.strictMode = value;
        m_service->updateConfig(cfg);
        emit configChanged();
    }
}

void EyeLeoViewModel::skipBreak() {
    if (m_service) m_service->skipBreak();
}

void EyeLeoViewModel::postponeLongBreak() {
    if (m_service) m_service->postponeLongBreak(3 * 60); // Hoãn lại 3 phút
}

void EyeLeoViewModel::dismissPrebreak() {
    m_isPrebreakActive = false;
    emit prebreakChanged();
}

void EyeLeoViewModel::triggerShortBreak() {
    if (m_service) m_service->triggerShortBreakNow();
}

void EyeLeoViewModel::triggerLongBreak() {
    if (m_service) m_service->triggerLongBreakNow();
}

} // namespace troly::presentation
