#pragma once

#include <cstdint>

namespace troly::domain {

/**
 * @brief Cấu hình bộ điều khiển bảo vệ mắt EyeLeo (C++20 Domain Entity)
 */
struct EyeLeoConfig {
    bool enabled{true};                     ///< Bật/tắt EyeLeo
    int32_t shortBreakIntervalSec{20 * 60}; ///< Chu kỳ nghỉ ngắn (20 phút)
    int32_t shortBreakDurationSec{20};      ///< Thời gian nghỉ ngắn (20 giây)
    int32_t longBreakIntervalSec{60 * 60};  ///< Chu kỳ nghỉ dài (60 phút)
    int32_t longBreakDurationSec{5 * 60};   ///< Thời gian nghỉ dài (5 phút)
    int32_t prebreakWarningSec{30};         ///< Báo trước khi nghỉ dài (30 giây)
    bool strictMode{false};                 ///< Chế độ nghiêm ngặt (không cho skip nghỉ dài)
    bool autoIdle{true};                    ///< Tự động nhận diện người dùng rời máy
    int32_t idleThresholdMs{180 * 1000};    ///< Ngưỡng coi là rời máy (3 phút)
};

enum class EyeLeoBreakType {
    None,
    PrebreakWarning,
    ShortBreak,
    LongBreak
};

} // namespace troly::domain
