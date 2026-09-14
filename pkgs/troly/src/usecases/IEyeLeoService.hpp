#pragma once

#include "../domain/EyeLeoConfig.hpp"
#include <functional>

namespace troly::usecases {

/**
 * @brief Interface thuần ảo điều khiển dịch vụ bảo vệ sức khỏe thị giác EyeLeo
 */
class IEyeLeoService {
public:
    virtual ~IEyeLeoService() = default;

    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void updateConfig(const domain::EyeLeoConfig& config) = 0;
    virtual domain::EyeLeoConfig getConfig() const = 0;

    virtual void skipBreak() = 0;
    virtual void postponeLongBreak(int32_t extraSec) = 0;
    virtual void triggerShortBreakNow() = 0;
    virtual void triggerLongBreakNow() = 0;

    virtual int32_t getWorkSeconds() const = 0;
    virtual domain::EyeLeoBreakType getActiveBreak() const = 0;
};

} // namespace troly::usecases
